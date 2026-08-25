// lib/core/constants/api_constants.dart
class ApiConstants {
  // Use your machine's IP for physical device testing;//'http://192.168.1.39:5000';//'https://fishbackend-znyn.onrender.com';//'http://10.113.122.169:5000';//'https://fishbackend-znyn.onrender.com';

  static const String baseUrl ='https://fishbackend-znyn.onrender.com';//'https://fishbackend-znyn.onrender.com';
  static const String apiBase = '/api';
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String profile = '/api/auth/profile';
  //  NEW: Self-registration
  static const String register = '/api/auth/register';

  // Locations
  static const String locations = '/api/locations';

  // Users
  static const String users = '/api/users';

  // Boats
  static const String boats = '/api/boats';

  // Fish
  static const String fish = '/api/fish';

  // Billing
  static const String bills = '/api/bills';

  // Bookings - NEW
  static const String bookings = '/api/bookings';

  // Ledger
  static const String ledger = '/api/ledger';

  // Tracking
  static const String tracking = '/api/tracking';

  // Reports
  static const String reports = '/api/reports';
  static const String revenueReport = '/api/reports/revenue';
  static const String revenueByFish = '/api/reports/revenue-by-fish';
  static const String revenueByLocation = '/api/reports/revenue-by-location';
  static const String billsSummary = '/api/reports/bills-summary';
  static const String auditLogs = '/api/reports/audit-logs';
  static const String dashboardSummary = '/api/reports/dashboard-summary';

  // Fish Buyer Bills
  static const String fishBuyerBills = '/api/fish-buyer-bills';
  static const String fishBuyerBillsByAgent = '/api/fish-buyer-bills/agent';

  // ── Boat Owner Module ──────────────────────────────────────────────────────
  static const String boatOwnerBase = '/api/boat-owner';
  static const String boatOwnerDashboard = '/api/boat-owner/dashboard';
  static const String boatOwnerBills = '/api/boat-owner/bills';
  static const String boatOwnerLedger = '/api/boat-owner/ledger';
  static const String boatOwnerLedgerSummary = '/api/boat-owner/ledger/summary';
  static const String boatOwnerFishingLocations =
      '/api/boat-owner/fishing-locations';
  static const String boatOwnerProfile = '/api/boat-owner/profile';
  static const String boatOwnerCrew = '/api/boat-owner/crew';
  static const String boatOwnerCaptains = '/api/boat-owner/crew/available/captains';
  static const String boatOwnerAvailableCrew = '/api/boat-owner/crew/available/crew';
  static const String boatOwnerVoyages = '/api/boat-owner/voyages';
  static const String boatOwnerVoyageStats = '/api/boat-owner/voyages/stats';
  static const String boatOwnerFish = '/api/boat-owner/fish';

  // Hauls
  static const String boatOwnerHauls = '/api/boat-owner/hauls';
  static const String boatOwnerActiveHaul = '/api/boat-owner/hauls/active';
  static const String boatOwnerRecentHauls = '/api/boat-owner/hauls/recent';

  // Catches
  static const String boatOwnerCatches = '/api/boat-owner/catches';
  static const String boatOwnerCatchesByHaul = '/api/boat-owner/catches/haul';
  static const String boatOwnerPendingCatch = '/api/boat-owner/catches/pending';

  // Fishing Grounds
  static const String boatOwnerFishingGrounds = '/api/boat-owner/fishing-grounds';
  static const String boatOwnerFavouriteGrounds = '/api/boat-owner/fishing-grounds/favourites';
  static const String boatOwnerGroundHistory = '/api/boat-owner/fishing-grounds/history';

  // GPS Tracks
  static const String boatOwnerGpsTracks = '/api/boat-owner/gps-tracks';
  static const String boatOwnerGpsTracksByVoyage = '/api/boat-owner/gps-tracks/voyage';
  static const String boatOwnerGpsTracksByHaul = '/api/boat-owner/gps-tracks/haul';
  static const String boatOwnerGpsTrackSummary = '/api/boat-owner/gps-tracks/summary';
  static const String boatOwnerGpsTrackHistory = '/api/boat-owner/gps-tracks/history';
  static const String boatOwnerGpsVoyageDetail = '/api/boat-owner/gps-tracks/voyage'; // + /:voyageId/detail

  // Voyage Dashboard sub-endpoints
  static const String boatOwnerVoyageCatchSummary = '/api/boat-owner/voyages'; // + /:voyageId/catch-summary
  static const String boatOwnerVoyageExpenses = '/api/boat-owner/voyage-expenses';
  static const String boatOwnerReturnEntry = '/api/boat-owner/voyages'; // + /:voyageId/return-entry
  static const String boatOwnerLandingEntry = '/api/boat-owner/voyages'; // + /:voyageId/landing-entry
  static const String boatOwnerChecklistDetails = '/api/boat-owner/voyages'; // + /:voyageId/checklist-details

  // Financial Management Endpoints
  static const String financialDashboard = '/api/boat-owner/financial/dashboard';
  static const String financialVoyages = '/api/boat-owner/financial/voyages';
  // Invoice Templates
  static const String invoiceTemplates = '/api/templates';
  static const String invoiceTemplatesActive = '/api/templates/active';
  static const String invoiceTemplatesAll = '/api/templates/all';
  static const String invoiceTemplateById = '/api/templates/{id}';
  static const String invoiceTemplateToggle = '/api/templates/{id}/toggle';

  //  NEW: Harbours
  static const String harbours = '/api/harbours';

  //  NEW: Registration Notifications (Super Admin)
  static const String notifications = '/api/notifications';
  static const String approveRegistration = '/api/notifications/{id}/approve';
  static const String rejectRegistration = '/api/notifications/{id}/reject';

  //  NEW: Subscription Plans
  static const String subscriptionPlans = '/api/subscription-plans';
  static const String subscriptionPlansActive = '/api/subscription-plans/active';
  static const String subscriptionPlansAll = '/api/subscription-plans/all';
  static const String subscriptionPlanById = '/api/subscription-plans/{id}';
  static const String subscriptionPlanToggle = '/api/subscription-plans/{id}/toggle';

  //  NEW: Subscription Lifecycle
  static const String mySubscription = '/api/subscription/my';
  static const String subscriptionActivePlans = '/api/subscription/plans';
  static const String createRenewalRequest = '/api/subscription/renewal';
  static const String renewalRequestStatus = '/api/subscription/renewal/status';
  static const String adminRenewalRequests = '/api/subscription/renewals';
  static const String approveRenewalRequest = '/api/subscription/renewals/{id}/approve';
  static const String rejectRenewalRequest = '/api/subscription/renewals/{id}/reject';

  //  NEW: My notifications (subscription warnings)
  static const String myNotifications = '/api/notifications/my';
  static const String markNotificationRead = '/api/notifications/{id}/read';

  //  NEW: Document Management Module
  static const String documents = '/api/documents';
  static const String documentsStats = '/api/documents/stats';
}
