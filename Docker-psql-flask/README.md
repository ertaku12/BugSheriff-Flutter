
### Useful Commands
```bash
docker exec -it postgresql bash
psql -U postgresql -d bugsheriff
```

### Sample database insert query:
```sql
INSERT INTO programs (name, description, application_start_date, application_end_date, status) VALUES
('Cyber Defenders Bug Hunt',
 'Scope: Web Applications, APIs, and Cloud Infrastructure. Look for Vulnerabilities such as XSS, SQL Injection, and Authentication Bypass. Rewards are Categorized as Low ($50-$150), Medium ($151-$500), and High ($501-$1000).',
 '10-01-2024',
 '12-31-2024',
 'Open'),

('Mobile Security Challenge',
 'Scope: iOS and Android Apps. Test for Insecure Data Storage, Improper Platform Usage, and Security Misconfigurations. Rewards: Low ($100), Medium ($300), High ($700).',
 '09-15-2024',
 '11-15-2024',
 'Closed'),

('E-commerce Bug Smash',
 'Scope: E-commerce Platform Including Checkout Process, User Accounts, and Payment Systems. Prioritize Finding Flaws like CSRF, IDOR, and Logic Flaws. Rewards: Low ($200), Medium ($500), High ($1200).',
 '11-01-2024',
 '01-31-2025',
 'Open'),

('Cloud Fortress PenTest',
 'Scope: AWS, Azure, and Google Cloud Platforms. Focus on Misconfigurations, Privilege Escalations, and Insecure API Gateways. Rewards: Low ($250), Medium ($750), High ($1500).',
 '12-01-2024',
 '02-01-2025',
 'Open'),

('IoT Device Security Crackdown',
 'Scope: Internet of Things (IoT) Devices and Their Companion Applications. Look for Issues like Insecure Firmware Updates, Weak Authentication, and Privacy Vulnerabilities. Rewards: Low ($100), Medium ($400), High ($900).',
 '10-15-2024',
 '12-15-2024',
 'Closed');