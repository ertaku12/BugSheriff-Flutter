# app/auth/routes.py
import uuid
from flask import request, jsonify, Flask, Blueprint, current_app as app, send_from_directory, send_file
from werkzeug.security import generate_password_hash, check_password_hash
from app.models import db, User, Program, Report
from flask_jwt_extended import create_access_token, JWTManager, jwt_required, get_jwt_identity
from app.config import Config
from flask_cors import CORS
import os
from functools import wraps


if not os.path.exists('uploads'):
    os.makedirs('uploads')

auth = Blueprint('auth', __name__)
#CORS(auth)

def admin_required(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        user = User.query.filter_by(username=get_jwt_identity()).first()
        if user.user_type != 'admin':
            return jsonify({"message": "Admins only!"}), 403
        return fn(*args, **kwargs)
    return wrapper

@auth.route('/admin/getreports', methods=['GET'])
@jwt_required()
@admin_required
def get_all_reports():

    # Kullanıcının raporlarını getir
    reports = Report.query.all()

    # Raporları JSON formatında döndür
    return jsonify([{
        'id': report.id,
        #'program_id': report.program_id,
        "iban": report.user.iban,
        'program_name': report.program.name,  # Program adını al
        'report_pdf_path': report.report_pdf_path,
        'status': report.status,
        'reward_amount': report.reward_amount
    } for report in reports]), 200

@auth.route('/admin/report/<int:report_id>', methods=['PUT'])
@jwt_required()
@admin_required
def update_report_status(report_id):
    data = request.json
    report = Report.query.get(report_id)
    if not report:
        return jsonify({"message": "Report not found"}), 404
    
    report.status = data.get('status', report.status)
    
    reward_amount = data.get('reward_amount', report.reward_amount)
    if isinstance(reward_amount, str):
        reward_amount = reward_amount.replace(',', '.')
    report.reward_amount = float(reward_amount)  # Ensure it's a float
    
    db.session.commit()
    return jsonify({"message": "Report updated"}), 200

@auth.route('/admin/newprogram', methods=['POST'])
@jwt_required()
@admin_required
def add_program():
    data = request.json
    # check all fields are filled
    if not data['name'] or not data['description'] or not data['application_start_date'] or not data['application_end_date'] or not data['status']:
        return jsonify({"message": "All fields must be filled"}), 400
    
    new_program = Program(
        name=data['name'],
        description=data['description'],
        application_start_date=data['application_start_date'],
        application_end_date=data['application_end_date'],
        status=data['status']
    )
    
    db.session.add(new_program)
    db.session.commit()
    return jsonify({"message": "Program added"}), 201

@auth.route('/admin/program/<int:program_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def delete_program(program_id):
    program = Program.query.get(program_id)

    if not program:
        return jsonify({"message": "Program not found"}), 404

    for report in program.reports:
        try:
            os.remove(os.path.join("uploads", report.report_pdf_path))
        except OSError as e:
            print(f"Error deleting file {report.report_pdf_path}: {e}")
    
    
    db.session.delete(program)
    db.session.commit()
    
    return jsonify({"message": "The program and its associated reports has been deleted!"}), 200

#edit
@auth.route('/admin/program/<int:program_id>', methods=['PUT'])
@jwt_required()
@admin_required
def update_program(program_id):
    data = request.json
    program = Program.query.get(program_id)
    if not program:
        return jsonify({"message": "Program not found"}), 404
    
    program.name = data.get('name', program.name)
    program.description = data.get('description', program.description)
    program.application_start_date = data.get('application_start_date', program.application_start_date)
    program.application_end_date = data.get('application_end_date', program.application_end_date)
    program.status = data.get('status', program.status)
    
    db.session.commit()
    return jsonify({"message": "Program updated"}), 200


@auth.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    if User.query.filter_by(username=username).first():
        return jsonify({"message": "User already exists."}), 400
    
    password = data.get('password')

    if username != 'admin':
        user_type = "user"
    else:
        user_type = "admin"
    
    secret_question = data.get("secret_question")
    secret_answer = data.get("secret_answer")
    
    if not username or not password or not secret_question or not secret_answer:
        return jsonify({"message": "All fields must be filled"}), 400
    iban = ""

    hashed_password = generate_password_hash(password, method='pbkdf2:sha256')
    new_user = User(username=username, password=hashed_password, user_type=user_type, 
        secret_question=secret_question, secret_answer=secret_answer, iban=iban)
    
    db.session.add(new_user)
    db.session.commit()

    return jsonify({"message": "User created successfully."}), 201

@auth.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    user = User.query.filter_by(username=username).first()
    
    if not user or not check_password_hash(user.password, password):
        return jsonify({"message": "Wrong username or password."}), 401

    access_token = create_access_token(identity=username)  # JWT oluştur
    return jsonify(access_token=access_token), 200

@auth.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    username = data.get('username')
    
    # Check if the user exists
    user = User.query.filter_by(username=username).first()
    if not user:
        return jsonify({"message": "User doesn't exist"}), 400
    
    password = data.get('password')

    # Check if the username is 'admin'
    # if username == 'admin':
    #     return jsonify({"message": "You are not authorized to reset admin's password!"}), 403

    secret_question = data.get("secret_question")
    secret_answer = data.get("secret_answer")
    
    if not username or not password or not secret_question or not secret_answer:
        return jsonify({"message": "All fields must be filled"}), 400

    # Check if secret question and answer match the existing records
    if user.secret_question != secret_question or user.secret_answer != secret_answer:
        return jsonify({"message": "Secret question/answer doesn't match!"}), 400
    
    hashed_password = generate_password_hash(password, method='pbkdf2:sha256')

    if user.password == hashed_password:
        return jsonify({"message": "New password must be different from the old password!"}), 400


    # Hash the new password and update user
    user.password = hashed_password
    
    # Commit the changes to the database
    db.session.commit()

    return jsonify({"message": "Password has been changed successfully."}), 200


@auth.route('/update-user', methods=['PUT'])
@jwt_required()
def update_user():
    data = request.get_json()
    current_user = get_jwt_identity()
    
    new_password = data.get('password')
    secret_question = data.get('secret_question')
    secret_answer = data.get('secret_answer')
    iban = data.get('iban')

    user = User.query.filter_by(username=current_user).first()
    if user:
        if new_password:
            user.password = generate_password_hash(new_password, method='pbkdf2:sha256')
        if secret_question:
            user.secret_question = secret_question
        if secret_answer:
            user.secret_answer = secret_answer  
        if iban:
            if len(iban) <= 34:
                user.iban = iban
            else:
                return jsonify({"message": "IBAN must be less than or equal to 34 characters"}), 400

        db.session.commit()
        return jsonify({"message": "User details updated successfully."}), 200
    else:
        return jsonify({"message": "User not found."}), 404
    

@auth.route('/user-details', methods=['GET'])
@jwt_required()
def user_details():
    current_user = get_jwt_identity()  # This will return the subject (sub) from the JWT

    # Query the user from the database
    user = User.query.filter_by(username=current_user).first()
    
    if user:
        return jsonify({
            "username": user.username,
            "secret_question": user.secret_question,
            "secret_answer": user.secret_answer,
            "iban": user.iban
        }), 200
    else:
        return jsonify({"message": "User not found."}), 404



@auth.route('/programs', methods=['GET'])
@jwt_required()
def programs():
    program_list = []
    
    # if the user is an admin, return all programs, else return only open programs
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    if user.user_type == 'admin':
        programs = Program.query.all()
    else:
        programs = Program.query.filter_by(status='Open').all()
    
    
    for program in programs:
        program_list.append({
            "id": program.id,
            "name": program.name,
            "description": program.description,
            "application_start_date": program.application_start_date,
            "application_end_date": program.application_end_date,
            "status": program.status
        })
    
    if len(program_list) > 0:
        return jsonify(program_list), 200
    else:
        return jsonify({"message": "Program not found"}), 404


@auth.route('/upload', methods=['POST'])
@jwt_required()
def upload_file():
    program_id = request.form['program_id']
    # check if the program application is still open
    # 2 choices: Open or Closed
    program = Program.query.get(program_id)
    if not program:
        return jsonify({"message": "Program not found"}), 404
    if program.status != 'Open':
        return jsonify({"message": "Program application is closed"}), 400
    
    # Get the current user's username (or any unique identifier you have)
    current_username = get_jwt_identity()

    # Fetch the current user from the database
    current_user = User.query.filter_by(username=current_username).first()

    if current_user is None:
        return jsonify({"message": "User not found"}), 404

    if 'file' not in request.files:
        return jsonify({"message": "No file part"}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({"message": "No selected file"}), 400
    
    #diff1
    #mimetype - didn't work on android
    # if file.mimetype != 'application/pdf':
    #     return jsonify({"message": "Only PDF files are allowed"}), 400
    
    #check file extension
    if not file.filename.endswith('.pdf'):
        return jsonify({"message": "Only PDF files are allowed"}), 400

    # Create a random filename
    random_filename = f"{uuid.uuid4()}.pdf"  # Generate a random name for the file
    file_path = os.path.join("uploads", random_filename)

    # Save the file
    file.save(file_path)

    # Create a new Report instance
    new_report = Report(
        user_id=current_user.id,  # User ID from the database
        program_id=request.form['program_id'],  # Get program ID from the form
        report_pdf_path=random_filename,  # PDF file path
        status='Pending',  # Report status (e.g., Pending)
        reward_amount=0.0  # Reward amount (initially empty)
    )

    # Add the new report to the database session
    db.session.add(new_report)
    db.session.commit()

    return jsonify({"message": "File uploaded successfully"}), 200

@auth.route('/reports', methods=['GET'])
@jwt_required()
def get_reports():
    current_username = get_jwt_identity()  # JWT'den kullanıcı kimliğini al
    user = User.query.filter_by(username=current_username).first()

    # Kullanıcının raporlarını getir
    reports = Report.query.filter_by(user_id=user.id).all()

    # Raporları JSON formatında döndür
    return jsonify([{
        'id': report.id,
        'program_id': report.program_id,
        'program_name': report.program.name,  # Program adını al
        'report_pdf_path': report.report_pdf_path,
        'status': report.status,
        'reward_amount': report.reward_amount
    } for report in reports]), 200


@auth.route('/uploads/<path:filename>', methods=['GET'])
@jwt_required()
def serve_uploaded_file(filename):
    current_username = get_jwt_identity()
    user = User.query.filter_by(username=current_username).first()
    report = Report.query.filter_by(report_pdf_path=filename).first()
    if not report:
        return jsonify({"message": "Report not found"}), 404
    if report.user_id != user.id:
        return jsonify({"message": "You are not authorized to view this file"}
        ), 403
    
    try:
        uploads_dir = os.path.join(os.getcwd(), 'uploads')
        return send_from_directory(uploads_dir, filename)
    except Exception as e:
        return jsonify({"message": "Internal Server Error"}), 500
    
@auth.route('/admin/uploads/<path:filename>', methods=['GET'])
@jwt_required()
@admin_required
def serve_file_to_admin(filename):
    try:
        uploads_dir = os.path.join(os.getcwd(), 'uploads')
        return send_from_directory(uploads_dir, filename)
    except Exception as e:
        return jsonify({"message": "Internal Server Error"}), 500


