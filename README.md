
# BugSheriff Bug Bounty Platform

## Project Description
This project is a bug bounty platform where users can report security vulnerabilities and earn rewards. Admin users can manage programs, add new programs, and review user reports.

## Features
- User and admin logins
- Program listing, adding, deleting, and updating
- User report management
- JWT authentication
- Mobile-friendly and user-friendly interface

## Requirements
- Flutter SDK
- Docker
- PostgreSQL

## Running the Project

### Run the Docker
1. Navigate to the project directory:
   ```bash
   cd Docker-psql-flask
   ```

2. Run the Docker Compose command:
   ```bash
   docker-compose up --build
   ```

### Run Flutter
1. Navigate to the project directory:
   ```bash
   cd bugheriff
   ```

2. Get the dependencies:
   ```bash
   flutter pub get
   ```

3. Run the project:
   ```bash
    flutter run
    ```

## Final Notes
   - Change the Flask API URL in the Flutter project to your database IP address.

- To stop and remove containers:
   ```bash
   docker-compose down 
   ```

- To remove volumes:
   ```bash
   docker volume rm docker-psql-flask_postgres_data

   docker volume rm docker-psql-flask_uploads
   ```


## Home Page
![Home Page](images/home_page.png)






