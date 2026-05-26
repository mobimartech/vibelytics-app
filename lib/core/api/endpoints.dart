/// Vibelytics API Endpoints
///
/// All endpoint paths as constants. Use these instead of hardcoding paths.
abstract class Endpoints {
  Endpoints._();

  static const String baseUrl = 'https://vibelytics.org';

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════════

  static const String authSignup = '/auth/signup';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authProfile = '/auth/profile';
  static const String authCheckUser = '/auth/check-user';
  static const String authOtpRequest = '/auth/otp/request';
  static const String authOtpVerify = '/auth/otp/verify';
  static const String authTelegramCallback = '/auth/telegram/callback';
  static const String authDeleteAccount = '/auth/account';

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYSIS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String analysis = '/analysis';
  static const String analysisChat = '/analysis/chat';
  static String analysisById(int id) => '/analysis/$id';
  static const String analysisList = '/analysis/list';
  static String analysisVoice(int id) => '/analysis/$id/voice';

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTOS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String photosEnhance = '/photos/enhance';
  static String enhanceStatus(int jobId) => '/photos/enhance/status/$jobId';
  static const String photosEnhanced = '/photos/enhanced';
  static String photoEnhancedDelete(int id) => '/photos/enhanced/$id';
  static const String cdnUpload = '/cdn/upload';
  static const String photos = '/photos';
  static const String photosFeed = '/photos/feed';
  static const String photosMyPhotos = '/photos/my-photos';
  static String photoDelete(int id) => '/photos/$id';
  static String photoPrivacy(int id) => '/photos/$id/privacy';
  static String photoRate(int id) => '/photos/$id';
  static String photoComment(int id) => '/photos/$id/comment';
  static String photoComments(int id) => '/photos/$id/comments';
  static String commentDelete(int id) => '/comments/$id';
  static String commentReport(int id) => '/comments/$id/report';
  static String photoReport(int id) => '/photos/$id/report';

  // ═══════════════════════════════════════════════════════════════════════════
  // LEADERBOARD
  // ═══════════════════════════════════════════════════════════════════════════

  static const String leaderboard = '/leaderboard';
  static String leaderboardByTag(String tag) => '/leaderboard/$tag';
  static String leaderboardUser(int id) => '/leaderboard/user/$id';
  static const String leaderboardStats = '/leaderboard/stats';
  static const String tags = '/tags';

  // ═══════════════════════════════════════════════════════════════════════════
  // CREDITS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String creditsBalance = '/credits/balance';
  static const String creditsHistory = '/credits/history';

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String subscriptionStatus = '/subscription/status';
  static const String subscriptionInitialize = '/subscription/initialize';

  // ═══════════════════════════════════════════════════════════════════════════
  // COUPONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String couponRedeem = '/coupon/redeem';
  static const String couponValidate = '/coupon/validate';
  static const String couponsPurchased = '/coupons/purchased';
  static const String purchasesStatus = '/purchases/status';

  // ═══════════════════════════════════════════════════════════════════════════
  // REFERRALS
  // ═══════════════════════════════════════════════════════════════════════════

  static const String referralMyCode = '/referral/my-code';
  static const String referralStats = '/referral/stats';
  static const String referralTrackClick = '/referral/track-click';

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVITY
  // ═══════════════════════════════════════════════════════════════════════════

  static const String activity = '/activity';
  static const String activityUnreadCount = '/activity/unread-count';
  static const String activityMarkRead = '/activity/mark-read';

  // ═══════════════════════════════════════════════════════════════════════════
  // APP VERSION
  // ═══════════════════════════════════════════════════════════════════════════

  static const String versionCheck = '/app/version-check';
}
