/// Route names untuk navigasi aplikasi
class AppRoutes {
  AppRoutes._(); // Private constructor

  // Root
  static const String splash = '/';
  
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  
  // Patient
  static const String patientHome = '/patient/home';
  static const String activityDetail = '/patient/activity/:id';
  static const String recognizeFace = '/patient/recognize-face';
  static const String patientProfile = '/patient/profile';
  
  // Family
  static const String familyHome = '/family/home';
  static const String dashboard = '/family/dashboard';
  static const String patientTracking = '/family/tracking';
  static const String manageActivities = '/family/activities';
  static const String addActivity = '/family/activities/add';
  static const String editActivity = '/family/activities/edit/:id';
  static const String knownPersons = '/family/persons';
  static const String addPerson = '/family/persons/add';
  static const String editPerson = '/family/persons/edit/:id';
  static const String familyProfile = '/family/profile';
  
  // Admin
  static const String adminHome = '/admin/home';
}
