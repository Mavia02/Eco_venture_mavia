class ApiConstants {
 //  // Change manually depending on test environment
 // static const String baseUrl = "http://10.0.2.2:5000/"; // Emulator
 // //static const String baseUrl = "http://192.168.0.182:5000/"; // Real Device
 //  static const String signInEndpoint = "${baseUrl}signIn";
 //  static const String signUpEndpoint =   "${baseUrl}signup";
 //  static const String googleEndpoint =   "${baseUrl}google";
 //  static const String getUserEndpoint = "${baseUrl}user";
 //  static const String chatEndpoint= "${baseUrl}chat";


  // Use your deployed Render backend

 // Use your deployed Render backend
 static const String baseUrl = "https://eco-venture-backend.onrender.com/";

 // Auth Endpoints
 static const String signInEndpoint = "${baseUrl}signIn";
 static const String signUpEndpoint = "${baseUrl}signup";
 static const String googleEndpoint = "${baseUrl}google";
 static const String getUserEndpoint = "${baseUrl}user";

 // Feature Endpoints
 static const String chatEndpoint = "${baseUrl}chat";

 // Student Management (CRITICAL: naming matched to Repository)
 static const String createStudentEndpoint = "${baseUrl}create-student";
 static const String deleteStudentEndpoint = "${baseUrl}delete-student"; // Added for permanent deletion

 // Notifications
 static const String notifyParentEndPoint = '${baseUrl}notify-parent';
 static const String notifyChildEndPoints = '${baseUrl}notify-child';
 static const String notifyChildClassEndPoints = '${baseUrl}notify-class';
 }


