import '../../data/models/content_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/models.dart';

/// Passed to `/register-code` for both the register and login OTP flows.
class CodeVerifyArgs {
  const CodeVerifyArgs({required this.email, required this.purpose});

  final String email;
  final OtpPurpose purpose;
}

/// Passed from the OTP verify step into the registration flow
/// (role-selection → age-selection → create-account).
class RegistrationArgs {
  const RegistrationArgs({required this.email, required this.registrationToken});

  final String email;
  final String registrationToken;
}

/// Carries the registration context plus the chosen role into
/// `/create-account`, where the account is actually created.
class CreateAccountArgs {
  const CreateAccountArgs({
    required this.email,
    required this.registrationToken,
    required this.role,
    this.suggestedAge,
  });

  final String email;
  final String registrationToken;
  final UserRole role;
  final int? suggestedAge;

  CreateAccountArgs copyWith({
    String? email,
    String? registrationToken,
    UserRole? role,
    int? suggestedAge,
  }) {
    return CreateAccountArgs(
      email: email ?? this.email,
      registrationToken: registrationToken ?? this.registrationToken,
      role: role ?? this.role,
      suggestedAge: suggestedAge ?? this.suggestedAge,
    );
  }
}

/// Passed to `/test-flow`: which test to load and whether the paid
/// (explanation-on-wrong-answer) variant of the flow should be shown.
class TestFlowArgs {
  const TestFlowArgs({required this.testId, required this.paid});

  final String testId;
  final bool paid;
}

/// Passed to `/test-result` with the real outcome of a completed attempt.
class TestResultArgs {
  const TestResultArgs({
    required this.testTitle,
    required this.correctCount,
    required this.totalCount,
    required this.paid,
  });

  final String testTitle;
  final int correctCount;
  final int totalCount;
  final bool paid;
}

/// Passed to `/tip-detail` with the guide section to show.
class TipDetailArgs {
  const TipDetailArgs({required this.section, required this.colorIndex});

  final GuideSection section;
  final int colorIndex;
}
