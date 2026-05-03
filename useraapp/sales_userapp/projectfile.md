Below is a clean + professional + production-style PRD for your Salesman Tracking App, with User App PRD and Admin App PRD separated (exactly the format you want).
I’m keeping it structured, scalable, and AI-Agent friendly so you can paste it directly into Google Antigravity / Cursor / Windsurf.
________________________________________
📄 PRD Part 1: Salesman Tracking App (User App Only)
________________________________________
📋 Table of Contents
1.	Project Overview
2.	Goals & Success Criteria
3.	User Persona
4.	Functional Requirements
5.	Firestore Data Model
6.	Architecture & Folder Structure
7.	Platform-Specific Behavior
8.	Dependency List
9.	Acceptance Criteria
10.	Roadmap Phases
11.	AI Agent Rules (PRD.md)
________________________________________
1. Project Overview
Field	Value
App Name	Salesman Tracker (User App)
Platform	Android + web + Windows
Framework	Flutter
Architecture	MVVM + flutter_bloc
Backend	Firebase Auth + Cloud Firestore
Map Package	flutter_map (OpenStreetMap)
One-liner Goal
Salesman login kare → Start Tracking press kare → app background me location capture kare → Firestore me sync kare → Admin live map me salesman ka location dekh sake.
Admin App Relation
•	Admin interval set karega in: settings/app_config
•	User App is document ko listen karega
•	Tracking interval dynamically update hoga (no restart required)
________________________________________
2. Goals & Success Criteria
Goals
•	Real-time salesman location capture
•	Reverse geocoding (lat/lng → readable address)
•	Admin-controlled interval sync
•	Background tracking (Android)
•	Stable tracking UI (simple & minimal)
Success Criteria (KPIs)
•	Location update latency < 30 seconds
•	Interval update within 1 minute after admin changes
•	Background tracking stable (Android)
•	Offline persistence works
•	Battery drain minimized using balanced accuracy
________________________________________
3. User Persona
Salesman (Field Agent)
Attribute	Detail
Role	Field Salesman
Device	Android phone (main), Windows laptop (secondary)
Tech Level	Basic
Need	One-click tracking
Pain Points	Tracking stop ho jana, complex UI
Expectation	Status clear show ho: Tracking ON/OFF
________________________________________
4. Functional Requirements
________________________________________
4.1 Authentication Module
Features
•	Email + Password login
•	Signup 
•	Auto-login
•	Logout
Screens
•	LoginScreen
•	SignupScreen
Error Handling
•	Incorrect password
•	User not found
•	Network issue
•	Weak password
________________________________________
4.2 Location Tracking Engine (Core)
Features
•	GPS capture using geolocator
•	Reverse geocoding using geocoding
•	Sync to Firestore
•	Write to active + history collections
Location Capture Config
•	Accuracy: LocationAccuracy.balanced
•	Distance filter: configurable (default 10m)
•	Interval: comes from Firestore settings listener
________________________________________
4.3 Reverse Geocoding
•	Convert lat/lng into readable address
•	If fails → store fallback:
"Unknown (lat, lng)"
________________________________________
4.4 Firestore Sync Rules
Every tick writes to:
A) active_locations/{userId} (upsert)
{
  "userId": "abc123",
  "name": "Rahul Kumar",
  "lat": 28.6139,
  "lng": 77.2090,
  "address": "Connaught Place, New Delhi",
  "timestamp": "now",
  "active": true,
  "updatedAt": "now"
}
B) locations/{autoId} (history)
{
  "userId": "abc123",
  "name": "Rahul Kumar",
  "lat": 28.6139,
  "lng": 77.2090,
  "address": "Connaught Place, New Delhi",
  "timestamp": "now",
  "active": true
}
________________________________________
4.5 Background Tracking
Android
•	Use flutter_background_service
•	Persistent notification:
"📍 Salesman Tracker is running"
•	Continue tracking even if app minimized
Windows
•	Timer-based tracking only while app is active
•	No background service
________________________________________
4.6 Dynamic Interval Listener
Firestore document:
settings/app_config
{
  "update_interval_seconds": 300,
  "min_distance_meters": 10.0,
  "updatedAt": "now"
}
Logic:
•	listen to snapshots
•	cancel old timer
•	start new timer with updated interval
Validation:
•	min interval: 15 sec
•	max interval: 3600 sec
•	default: 300 sec
________________________________________
4.7 Device Status Management
Tracking Start:
•	active=true
•	users/{userId}.status="tracking"
Tracking Stop:
•	active=false
•	users/{userId}.status="idle"
App kill (Android):
•	best effort set active=false
________________________________________
4.8 Tracking Control UI
Screen: TrackingScreen
Must show:
•	last address
•	last updated time
•	current interval
•	tracking status badge
•	start/stop button
•	logout button
________________________________________
4.9 Permission Handling
Android required permissions:
•	ACCESS_FINE_LOCATION
•	ACCESS_COARSE_LOCATION
•	ACCESS_BACKGROUND_LOCATION
•	FOREGROUND_SERVICE
•	POST_NOTIFICATIONS
Windows:
•	location capability enabled
Flow:
•	Start Tracking pressed → request permission
•	if denied permanently → show settings redirect
________________________________________
4.10 Offline Network Handling
If Firestore fails:
•	store locally
•	sync later when online
Prefer using Firestore offline persistence.
________________________________________
5. Firestore Data Model
Collections Written
users/{userId}
{
  "uid": "abc123",
  "email": "salesman@company.com",
  "name": "Rahul Kumar",
  "role": "salesman",
  "status": "tracking",
  "createdAt": "now",
  "lastActiveAt": "now"
}
active_locations/{userId}
{
  "userId": "abc123",
  "name": "Rahul Kumar",
  "lat": 28.6139,
  "lng": 77.2090,
  "address": "Delhi",
  "timestamp": "now",
  "active": true,
  "updatedAt": "now"
}
locations/{docId}
{
  "userId": "abc123",
  "name": "Rahul Kumar",
  "lat": 28.6139,
  "lng": 77.2090,
  "address": "Delhi",
  "timestamp": "now",
  "active": true
}
Collection Read
settings/app_config
{
  "update_interval_seconds": 300,
  "min_distance_meters": 10.0,
  "updatedAt": "now"
}
________________________________________
6. Architecture & Folder Structure
Architecture: MVVM + flutter_bloc
Layers:
•	Presentation (UI only)
•	Bloc/Cubit (ViewModel)
•	Repository (business logic)
•	Provider (Firebase wrappers)
•	Models
Folder structure same as your provided one (recommended).
________________________________________
7. Platform-Specific Behavior
Android
•	Background service enabled
•	Foreground notification mandatory
•	Battery optimization balanced
Windows
•	Tracking works while app open
•	No background services
________________________________________
8. Dependency List
dependencies:
  flutter:
    sdk: flutter

  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0

  geolocator: ^11.0.0
  geocoding: ^3.0.0

  flutter_background_service: ^5.0.0
  flutter_local_notifications: ^17.0.0

  flutter_screenutil: ^5.9.0

  flutter_map: ^6.1.0
  latlong2: ^0.9.1

  intl: ^0.19.0
  connectivity_plus: ^5.0.0
  shared_preferences: ^2.2.0
________________________________________
9. Acceptance Criteria
✔ Auth works
✔ Tracking starts/stops properly
✔ Firestore writes happen correctly
✔ Interval updates dynamically
✔ Background works on Android
✔ UI responsive Android + Windows
✔ Offline persistence works
________________________________________
10. Roadmap Phases
Phase 1: Foundation
Phase 2: Authentication
Phase 3: Tracking Engine
Phase 4: Background + Polish
Phase 5: Testing + Optimization
________________________________________
11. AI Agent Rules (PRD.md)
Create PRD.md file with rules (same as your draft).
(Your rules are already excellent; no changes required.)
________________________________________
________________________________________
________________________________________

