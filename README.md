Guard Resource App
A full-stack mobile application designed to provide centralized resources for National Guard service members. Built with Flutter (frontend) and a Node.js/Express backend, the application focuses on secure authentication, clean navigation, and scalable architecture.
Features
•	JWT-based Authentication (Login / Register)
•	Cross-platform Flutter UI (Android and Web)
•	Organized resource navigation system
•	RESTful API backend
•	Secure password hashing using bcrypt
•	Scalable backend structure
•	Clean routing and navigation flow
Technology Stack
Frontend
•	Flutter
•	Dart
•	Provider (State Management)
•	HTTP package
Backend
•	Node.js
•	Express.js
•	JWT (Authentication)
•	bcrypt (Password hashing)
•	MongoDB
Project Structure
guard-resource-app/
│
├── frontend/        Flutter application
│   ├── lib/
│   ├── main.dart
│   └── pubspec.yaml
│
├── backend/         Express API server
│   ├── routes/
│   ├── controllers/
│   ├── middleware/
│   └── server.js
│
└── README.md
Installation and Setup
1. Clone the Repository
git clone https://github.com/felix-src/guardapp_nj.git
cd guardapp_nj
2. Backend Setup
cd backend
npm install

Create a .env file inside the backend folder with the following:

PORT=5000
JWT_SECRET=your_secret_key_here
DATABASE_URL=your_database_connection_string

Run the server:
npm start

Server runs at http://localhost:5000
3. Frontend Setup
cd frontend
flutter pub get
flutter run

Ensure an emulator or physical device is running.
Security Notes
•	Passwords are hashed using bcrypt.
•	JWT tokens are signed using a secret stored in the .env file.
•	Sensitive files are excluded via .gitignore.
•	Never commit .env files, API keys, or database credentials.
Example API Request
POST /auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}

A successful login returns a signed JWT token.
Roadmap
•	Role-based access control
•	Resource categorization system
•	Push notifications
•	Cloud deployment (AWS, Render, or Railway)
•	CI/CD pipeline integration
Author
Felix Lopez
Information Technology Student
U.S. Army National Guard
Cybersecurity and Software Development
License
This project is for educational and portfolio purposes.
