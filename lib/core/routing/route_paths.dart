/// Central route path constants.
abstract final class RoutePaths {
  static const splash = '/splash';
  static const auth = '/auth';
  static const verifyOtp = '/auth/verify-otp';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const weightSetup = '/onboarding/weight';
  static const paywall = '/onboarding/paywall';

  static const home = '/home';
  static const scan = '/scan';
  static const log = '/log';
  static const events = '/events';
  static const createEvent = '/events/create';
  static const eventDetail = '/events/detail/:id';
  static const myEvents = '/events/mine';
  static const editEvent = '/events/edit';
  static const shareMeal = '/meals/share';
  static const shareMealChooser = '/meals/share/choose';
  static const shareExistingMeal = '/meals/share/existing';
  static const starredMeals = '/meals/starred';
  static const publicProfile = '/users/:id';
  static const profile = '/profile';

  static const profilePersonal = '/profile/personal';
  static const profilePreferences = '/profile/preferences';
  static const profileLanguage = '/profile/language';
  static const profileNutrition = '/profile/nutrition';
  static const profileReferrals = '/profile/referrals';
  static const profileClan = '/profile/clan';
  static const profileShare = '/profile/share';
  static const coaches = '/coaches';
  static const coachDetail = '/coaches/:id';
  static const profileTerms = '/profile/terms';
  static const profilePrivacy = '/profile/privacy';
  static const shareClientDiary = '/share/client/:id';
  static const shareJoin = '/share/join';

  static String coachDetailPath(String id) => '/coaches/$id';

  static const logExercise = '/log_exercise';
  static const runIntensity = '/run_intensity';
  static const weightLifting = '/weight_lifting';
  static const describeExercise = '/describe_exercise';
  static const manualExercise = '/manual_exercise';

  static const foodDatabase = '/food_database';
  static const foodDetail = '/food-detail';
  static const fixResults = '/fix-results';
  static const featureRequest = '/feature_request';

  static const tasks = '/tasks';
  static const createTask = '/tasks/create';
  static const taskTimer = '/tasks/timer';
}
