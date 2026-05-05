# TechLead – Admin & Staff Management System 🚀

TechLead is a comprehensive Flutter-based admin and staff management application designed to streamline employee operations such as attendance tracking, location monitoring, reporting, and communication.

The app integrates Firebase services to provide a secure, scalable, and real-time management system for organizations.

---

## ✨ Key Features

### 👥 Employee Management

* Add, update, and delete staff members
* Secure authentication using Firebase Auth
* Role-based access for admin and staff

### 🕒 Attendance System

* Daily check-in and check-out functionality
* Automatic check-out after 9 working hours
* Full-day / Half-day status calculation
* Attendance history tracking

### 📍 Location Tracking

* Capture employee location during check-in/check-out
* Google Maps integration for location visualization
* Geolocation-based validation

### 📅 Calendar & Scheduling

* Interactive calendar for attendance overview
* Monthly and yearly filtering
* Admin-level scheduling and tracking

### 🔔 Notifications & Alerts

* Push notifications using Firebase Messaging
* Local notifications for reminders and updates

### 📊 Reports & Analytics

* Generate reports in PDF and Excel formats
* Visual analytics using charts and graphs
* Export and share reports

### 📂 File & Document Management

* Upload and manage files (images, PDFs, docs)
* Firebase Storage integration
* Open and share documents directly

### 📧 Communication

* Send emails directly from the app
* Share reports and documents

### ⚡ Performance & UX

* Smooth UI with animations (Lottie, Shimmer)
* Optimized image loading
* Responsive design for multiple devices

---

## 🛠️ Tech Stack

* **Frontend:** Flutter, Dart
* **State Management:** Provider, Riverpod
* **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions)
* **APIs & Networking:** Dio, HTTP
* **Local Storage:** SharedPreferences, SQLite

---

## ⚙️ Backend Automation (Cloud Functions)

* 🔹 Automatic user deletion from Firebase Authentication
* 🔹 Scheduled auto check-out system

    * Runs daily
    * Marks checkout after 9 hours
    * Calculates working duration
    * Assigns attendance status (Full/Half Day)

---

## 📸 Screenshots

<!-- Add your screenshots here -->

![Dashboard](images/dashboard.png)
![Attendance](images/attendance.png)
![Reports](images/reports.png)

---

## 🚀 Getting Started

```bash
git clone https://github.com/your-username/techlead.git
cd techlead
flutter pub get
flutter run
```

---

## 🔐 Security Features

* Firebase App Check integration
* Secure API handling with environment variables
* Permission handling for sensitive features
