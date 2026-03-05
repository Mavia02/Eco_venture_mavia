import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  SharedPreferencesHelper._();

  static SharedPreferencesHelper instance =
  SharedPreferencesHelper._();
  static String userIdKey = 'USERIDKEY';
  static String userNameKey = 'USERNAMEKEY';
  static String userEmailKey = 'USEREMAILKEY';
  static String userRoleKey = 'USERROLEKEY';
  static String userPhoneNumberKey = 'USERPHONENUMBERKEY';
  static String userImgUrlKey = 'USERIMGURLKEY';
  static String userDOBKey = 'USERDOBKEY';
  static String userTokenKey = 'USERTOKENKEY';
  static String userImageUrlKey='USERIMAGEURLKEY';
  static String userAgeGroupKey = 'USERAGEGROUPKEY'; // Added Age Group Key
  static const String childTeacherIdKey = 'child_teacher_id';
  static const String isTeacherAddedKey = 'is_teacher_added';
  static const String childNameKey = 'child_name';
  static const String childEmailKey = 'child_email';


  Future<bool> saveUserId(String userId) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userIdKey, userId);
  }
  Future<bool> saveUserImgUrl(String imgUrl)async{
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userImgUrlKey, imgUrl);
  }
  Future<bool> saveUserName(String userName) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userNameKey, userName);
  }

  Future<bool> saveUserEmail(String userEmail) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userEmailKey, userEmail);
  }
  Future<bool> saveUserDOB(String dOB) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userDOBKey, dOB);
  }

  Future<bool> saveUserRole(String userRole) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userRoleKey, userRole);
  }

  // --- NEW: Save Age Group ---
  Future<bool> saveUserAgeGroup(String ageGroup) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userAgeGroupKey, ageGroup);
  }

  Future<bool> saveUserToken(String userToken) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userTokenKey, userToken);
  }

  Future<bool> saveUserPhoneNumber(String userPhoneNumber) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userPhoneNumberKey, userPhoneNumber);
  }


  Future<String?> getUserId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userIdKey);
  }

  Future<String?> getUserEmail() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userEmailKey);
  }

  Future<String?> getUserName() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userNameKey);
  }

  Future<String?> getUserPhoneNumber() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userPhoneNumberKey);
  }

  Future<String?> getUserRole() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userRoleKey);
  }

  // --- NEW: Get Age Group ---
  Future<String?> getUserAgeGroup() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userAgeGroupKey);
  }

  Future<String?> getImageUrl() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userImgUrlKey);
  }
  Future<String?> getUserDOB() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userDOBKey);
  }

  Future<String?> getUserImgUrl() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userImgUrlKey);
  }

  // Children Added By Teacher

  Future<bool> saveChildName(String name) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(childNameKey, name);
  }

  Future<String?> getChildName() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(childNameKey);
  }

  // 2. Save/Get Child Email
  Future<bool> saveChildEmail(String email) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(childEmailKey, email);
  }

  Future<String?> getChildEmail() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(childEmailKey);
  }

  // 3. Save the ID of the Teacher who added this child
  Future<bool> saveChildTeacherId(String teacherId) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(childTeacherIdKey, teacherId);
  }

  // 4. Get that Teacher's ID (Used to fetch teacher's quizzes)
  Future<String?> getChildTeacherId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(childTeacherIdKey);
  }

  // 5. Flag: Was this child added by a teacher?
  Future<bool> saveIsTeacherAdded(bool isAdded) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setBool(isTeacherAddedKey, isAdded);
  }

  Future<bool> getIsTeacherAdded() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(isTeacherAddedKey) ?? false;
  }

  Future<void> clearAll() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(userIdKey);
    await pref.remove(userNameKey);
    await pref.remove(userEmailKey);
    await pref.remove(userRoleKey);
    await pref.remove(userPhoneNumberKey);
    await pref.remove(userImgUrlKey);
    await pref.remove(userDOBKey);
    await pref.remove(userTokenKey);
    await pref.remove(userAgeGroupKey); // Clear age group on logout
    await pref.remove(childTeacherIdKey);
    await pref.remove(isTeacherAddedKey);
    await pref.remove(childNameKey);
    await pref.remove(childEmailKey);
  }

}
