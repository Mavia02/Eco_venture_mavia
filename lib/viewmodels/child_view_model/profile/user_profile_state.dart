class UserProfileState {
  final bool isLoading;
  final String? error;
  final String? teacherName; // NEW: Added to store teacher's name
  final Map<String, dynamic>? userProfile;

  UserProfileState({
    required this.isLoading,
    this.error,
    this.teacherName,
    this.userProfile,
  });

  factory UserProfileState.initial() {
    return UserProfileState(
      isLoading: false,
      error: null,
      teacherName: null,
      userProfile: null,
    );
  }

  UserProfileState copyWith({
    bool? isLoading,
    String? error,
    String? teacherName,
    Map<String, dynamic>? userProfile,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      teacherName: teacherName ?? this.teacherName, // Maintain current if not provided
      userProfile: userProfile ?? this.userProfile,
    );
  }
}
