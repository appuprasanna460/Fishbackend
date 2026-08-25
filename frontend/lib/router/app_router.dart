// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/providers/pin_provider.dart';
import '../features/boats/presentation/providers/boat_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/select_harbour_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/pin_entry_screen.dart';
import '../features/locations/presentation/screens/location_management_screen.dart';
import '../features/users/presentation/screens/user_list_screen.dart';
import '../features/users/presentation/screens/user_form_screen.dart';
import '../features/users/presentation/screens/user_detail_screen.dart';
import '../features/boats/presentation/screens/boat_list_screen.dart';
import '../features/boats/presentation/screens/boat_form_screen.dart';
import '../features/boats/presentation/screens/boat_detail_screen.dart';
import '../features/fish/presentation/screens/fish_list_screen.dart';
import '../features/fish/presentation/screens/fish_form_screen.dart';
import '../features/billing/presentation/screens/bill_list_screen.dart';
import '../features/billing/presentation/screens/bill_tab_screen.dart';
import '../features/billing/presentation/screens/billing_form_screen.dart';
import '../features/billing/presentation/screens/bill_detail_screen.dart';
import '../features/ledger/presentation/screens/ledger_screen.dart';
import '../features/ledger/presentation/screens/boat_balance_screen.dart';
import '../features/tracking/presentation/screens/fish_price_analytics_screen.dart';
import '../features/tracking/presentation/screens/tracking_map_screen.dart';
import '../features/dashboard/presentation/screens/fish_market_dashboard.dart';
import '../features/dashboard/presentation/screens/harbour_management_screen.dart';
import '../features/dashboard/presentation/screens/harbour_users_screen.dart';
import '../features/dashboard/presentation/screens/notification_list_screen.dart';
import '../features/commission_agent/presentation/screens/commission_agent_dashboard.dart';
import '../features/commission_agent/presentation/screens/staff_management_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_dashboard.dart';
import '../features/boat_owner/presentation/screens/boat_owner_ledger_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_bill_list_screen.dart';
import '../features/boat_owner/presentation/screens/fishing_location_screen.dart';
import '../features/commission_agent/presentation/screens/boat_booking_screen.dart';
import '../features/commission_agent/presentation/screens/booking_history_screen.dart';
import '../features/staff/presentation/screens/staff_dashboard.dart';
import '../features/fish_buyer/presentation/screens/fish_buyer_dashboard.dart';
import '../features/fish_buyer/presentation/screens/fish_buyer_bill_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/reports/presentation/screens/audit_log_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/more/presentation/screens/more_screen.dart';
import '../core/widgets/app_fish_market_nav_bar.dart';
import '../features/commission_agent/presentation/screens/agent_fish_buyer_bills_screen.dart';
import '../core/utils/secure_storage.dart';

// ✅ NEW: Import Invoice Template Screen
import '../features/invoice_template/presentation/screens/invoice_template_screen.dart';

// ✅ NEW: Import Subscription Plan Screen
import '../features/subscription_plan/presentation/screens/package_list_screen.dart';

// ✅ NEW: Import Subscription Lifecycle Screens
import '../features/subscription_plan/presentation/screens/subscription_detail_screen.dart';
import '../features/subscription_plan/presentation/screens/plan_selection_screen.dart';
import '../features/subscription_plan/presentation/screens/expired_subscription_screen.dart';

import '../features/boat_owner/presentation/screens/boat_owner_boats.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyages_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_wizard.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_detail.dart';
import '../features/boat_owner/presentation/screens/boat_owner_menu_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_profile_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_management_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_crew_form.dart';
import '../features/boat_owner/presentation/screens/boat_owner_fishing_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_haul_form.dart';
import '../features/boat_owner/presentation/screens/boat_owner_haul_dashboard.dart';
import '../features/boat_owner/presentation/screens/boat_owner_haul_summary.dart';
import '../features/boat_owner/presentation/screens/boat_owner_catch_form.dart';
import '../features/boat_owner/presentation/screens/gps_track_history_screen.dart';
import '../features/boat_owner/presentation/screens/gps_track_all_screen.dart';
import '../features/boat_owner/presentation/screens/gps_track_voyage_detail_screen.dart';

// New screen imports
import '../features/boat_owner/presentation/screens/company_profile_screen.dart';
import '../features/billing/presentation/screens/billing_history_screen.dart';
import '../features/boat_owner/presentation/screens/team_users_screen.dart';
import '../features/boat_owner/presentation/screens/team_member_details_screen.dart';
import '../features/auth/presentation/screens/change_pin_screen.dart';
import '../features/profile/presentation/screens/language_settings_screen.dart';
import '../features/profile/presentation/screens/personal_info_screen.dart';

// Fleet Management Screens
import '../features/fleet/presentation/screens/fleet_dashboard_screen.dart';
import '../features/fleet/presentation/screens/fleet_comparison_screen.dart';
import '../features/fleet/presentation/screens/fleet_profitability_screen.dart';
import '../features/fleet/presentation/screens/fleet_crew_allocation_screen.dart';
import '../features/fleet/presentation/screens/fleet_calendar_screen.dart';
import '../features/fleet/presentation/screens/fleet_insights_screen.dart';

// ✅ NEW: Import Document Module Screens
import '../features/boat_owner/presentation/screens/document_dashboard_screen.dart';
import '../features/boat_owner/presentation/screens/document_list_screen.dart';
import '../features/boat_owner/presentation/screens/document_detail_screen.dart';
import '../features/boat_owner/presentation/screens/add_document_screen.dart';
import '../features/boat_owner/presentation/screens/crew_documents_screen.dart';
import '../features/boat_owner/presentation/screens/upload_crew_proof_screen.dart';

// ✅ NEW: Import Financial Module Screens
import '../features/boat_owner/presentation/screens/financial_dashboard_screen.dart';
import '../features/boat_owner/presentation/screens/financial_voyage_list_screen.dart';
import '../features/boat_owner/presentation/screens/financial_voyage_summary_screen.dart';

import '../features/boat_owner/presentation/screens/fishing_ground_history_screen.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_departure_checklist.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_logbook.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_catch_summary.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_expenses.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_summary.dart';
import '../features/boat_owner/presentation/screens/boat_owner_voyage_entry.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
// Separate navigator keys per shell so GoRouter keeps each shell's page stack.
final _adminShellKey = GlobalKey<NavigatorState>();
final _agentShellKey = GlobalKey<NavigatorState>();
final _ownerShellKey = GlobalKey<NavigatorState>();
final _buyerShellKey = GlobalKey<NavigatorState>();
final _staffShellKey = GlobalKey<NavigatorState>();

/// Public routes that do not require authentication
const _publicRoutes = {'/welcome', '/login', '/select-harbour', '/register', '/pin-entry'};

GoRouter? _routerInstance;

final appRouterProvider = Provider<GoRouter>((ref) {
  _routerInstance ??= GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final authState = ref.read(authProvider);
      final pinState = ref.read(pinProvider);
      final loc = state.matchedLocation;

      // Auth is initializing or loading -> wait
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      // ── Unauthenticated ──────────────────────────────────────────────
      if (!authState.isAuthenticated) {
        if (_publicRoutes.any((r) => loc.startsWith(r))) return null;
        return '/welcome';
      }

      // ── Authenticated ────────────────────────────────────────────────

      // 30-day session expiry check
      final lastLogin = await SecureStorage.getLastLoginDate();
      if (lastLogin != null) {
        final lastLoginDate = DateTime.tryParse(lastLogin);
        if (lastLoginDate != null) {
          final daysSince = DateTime.now().difference(lastLoginDate).inDays;
          if (daysSince >= 30) {
            await ref.read(authProvider.notifier).logout();
            return '/welcome';
          }
        }
      }

      // PIN Lock enforcement: If PIN is set and app is currently locked, force PIN Entry Screen
      if (pinState.hasPinSet && !pinState.isUnlocked && loc != '/pin-entry') {
        return '/pin-entry';
      }

      // If user is authenticated & unlocked, but tries to access public pages, redirect to default dashboard
      if (loc == '/welcome' || loc == '/login' || loc == '/pin-entry') {
        return _defaultRouteForRole(authState.user?.role ?? '');
      }

      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/select-harbour',
        builder: (_, __) => const SelectHarbourScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RegisterScreen(
            harbourId: extra['harbourId'] as String? ?? '',
            harbourName: extra['harbourName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/pin-entry',
        builder: (_, __) => const PinEntryScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),

      // ── Subscription routes (top-level, accessible from any role) ────────
      GoRoute(
        path: '/subscription-detail',
        builder: (_, __) => const SubscriptionDetailScreen(),
      ),
      GoRoute(
        path: '/plan-selection',
        builder: (_, __) => const PlanSelectionScreen(),
      ),
      GoRoute(
        path: '/subscription-expired',
        builder: (_, __) => const ExpiredSubscriptionScreen(),
      ),

      // ── Settings / Details screens (Root-level to allow push transitions from any shell/screen) ──
      GoRoute(
        path: '/owner/company-profile',
        builder: (_, __) => const CompanyProfileScreen(),
      ),
      GoRoute(
        path: '/owner/billing-history',
        builder: (_, __) => const BillingHistoryScreen(),
      ),
      GoRoute(
        path: '/owner/team',
        builder: (_, __) => const TeamUsersScreen(),
      ),
      GoRoute(
        path: '/owner/team/:id',
        builder: (_, state) => TeamMemberDetailsScreen(
          memberId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/owner/language-settings',
        builder: (_, __) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: '/owner/change-pin',
        builder: (_, __) => const ChangePinScreen(),
      ),
      GoRoute(
        path: '/owner/personal-info',
        builder: (_, __) => const PersonalInfoScreen(),
      ),

      // ── Super Admin shell ────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) =>
            _AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const FishMarketDashboard(),
          ),
          GoRoute(
            path: '/admin/locations',
            builder: (_, __) => const LocationManagementScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UserListScreen(),
          ),
          GoRoute(
            path: '/admin/users/new',
            builder: (_, __) => const UserFormScreen(),
          ),
          GoRoute(
            path: '/admin/users/:id',
            builder: (_, s) =>
                UserDetailScreen(userId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/users/:id/edit',
            builder: (_, s) => UserFormScreen(userId: s.pathParameters['id']),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/admin/audit-log',
            builder: (_, __) => const AuditLogScreen(),
          ),
          // ✅ NEW: Invoice Template Management Route
          GoRoute(
            path: '/admin/invoice-templates',
            builder: (_, __) => const InvoiceTemplateScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (_, __) => const BoatOwnerProfileScreen(),
          ),
          GoRoute(
            path: '/admin/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
          // ✅ NEW: Harbour Management
          GoRoute(
            path: '/admin/harbours',
            builder: (_, __) => const HarbourManagementScreen(),
          ),
          // ✅ NEW: Harbour Users List
          GoRoute(
            path: '/admin/harbours/:id/users',
            builder: (_, s) => HarbourUsersScreen(
              harbourId: s.pathParameters['id']!,
              harbourName: s.uri.queryParameters['name'] ?? 'Harbour',
            ),
          ),
          // ✅ NEW: Pending Registrations (Notifications)
          GoRoute(
            path: '/admin/notifications',
            builder: (_, __) => const NotificationListScreen(),
          ),
          // ✅ NEW: Subscription Packages
          GoRoute(
            path: '/admin/packages',
            builder: (_, __) => const PackageListScreen(),
          ),
          // ✅ NEW: More (menu hub)
          GoRoute(
            path: '/admin/more',
            builder: (_, __) => const MoreScreen(),
          ),
        ],
      ),

      // ── Commission Agent shell ───────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _agentShellKey,
        builder: (context, state, child) =>
            _AgentShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/agent/dashboard',
            builder: (_, __) => const CommissionAgentDashboard(),
          ),
          GoRoute(
            path: '/agent/boats',
            builder: (_, __) => const BoatListScreen(),
          ),
          GoRoute(
            path: '/agent/boats/:id',
            builder: (_, s) =>
                BoatDetailScreen(boatId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/agent/bills/new',
            builder: (_, __) => const BillingFormScreen(tabIndex: 0),
          ),
          GoRoute(
            path: '/agent/bills',
            builder: (_, __) => const BillingFormScreen(tabIndex: 1),
          ),
          GoRoute(
            path: '/agent/bills/:id',
            builder: (_, s) =>
                BillDetailScreen(billId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/agent/bills/:id/edit',
            builder: (_, s) =>
                BillingFormScreen(billId: s.pathParameters['id'], tabIndex: 0),
          ),
          GoRoute(
            path: '/agent/fish-buyer-bills',
            builder: (_, __) => const AgentFishBuyerBillsScreen(),
          ),
          GoRoute(
            path: '/agent/ledger',
            builder: (_, __) => const LedgerScreen(),
          ),
          GoRoute(
            path: '/agent/ledger/boat/:boatId',
            builder: (_, s) =>
                BoatBalanceScreen(boatId: s.pathParameters['boatId']!),
          ),
          GoRoute(
            path: '/agent/tracking',
            builder: (_, __) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/agent/staff',
            builder: (_, __) => const StaffManagementScreen(),
          ),
          GoRoute(
            path: '/agent/bookings',
            builder: (_, __) => const BookingHistoryScreen(),
          ),
          GoRoute(
            path: '/agent/profile',
            builder: (_, __) => const BoatOwnerProfileScreen(),
          ),
          GoRoute(
            path: '/agent/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
        ],
      ),

      // ── Boat Owner shell ─────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _ownerShellKey,
        builder: (context, state, child) =>
            _OwnerShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/owner/dashboard',
            builder: (_, __) => const BoatOwnerDashboard(),
          ),
          GoRoute(
            path: '/owner/fleet',
            builder: (_, __) => const FleetDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/fleet/compare',
            builder: (_, __) => const FleetComparisonScreen(),
          ),
          GoRoute(
            path: '/owner/fleet/profitability',
            builder: (_, __) => const FleetProfitabilityScreen(),
          ),
          GoRoute(
            path: '/owner/fleet/crew-allocation',
            builder: (_, __) => const FleetCrewAllocationScreen(),
          ),
          GoRoute(
            path: '/owner/fleet/calendar',
            builder: (_, __) => const FleetCalendarScreen(),
          ),
          GoRoute(
            path: '/owner/fleet/insights',
            builder: (_, __) => const FleetInsightsScreen(),
          ),
          GoRoute(
            path: '/owner/voyages',
            builder: (_, __) => const BoatOwnerVoyagesScreen(),
          ),
          GoRoute(
            path: '/owner/voyages/new',
            builder: (_, __) => const BoatOwnerVoyageWizard(),
          ),
          GoRoute(
            path: '/owner/voyages/:id/edit',
            builder: (_, s) => BoatOwnerVoyageWizard(voyageId: s.pathParameters['id']),
          ),
          GoRoute(
            path: '/owner/voyages/:id',
            builder: (_, s) =>
                BoatOwnerVoyageDetail(voyageId: s.pathParameters['id']!),
          ),
          // ── Voyage Dashboard sub-routes ──────────────────────────────────
          GoRoute(
            path: '/owner/voyages/:id/checklist',
            builder: (_, s) => BoatOwnerVoyageDepartureChecklist(
                voyageId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/voyages/:id/entry',
            builder: (_, s) => BoatOwnerVoyageEntryScreen(
                voyageId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/voyages/:id/logbook',
            builder: (_, s) => BoatOwnerVoyageLogbook(
                voyageId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/voyages/:id/timeline',
            builder: (_, s) => BoatOwnerVoyageLogbook(
                voyageId: s.pathParameters['id']!,
                startOnTimeline: true),
          ),
          GoRoute(
            path: '/owner/voyages/:id/catch',
            builder: (_, s) => BoatOwnerVoyageCatchSummary(
                voyageId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/voyages/:id/expenses',
            builder: (_, s) =>
                BoatOwnerVoyageExpenses(voyageId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/voyages/:id/summary',
            builder: (_, s) =>
                BoatOwnerVoyageSummary(voyageId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/logbook',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Logbook Coming Soon in Phase 2')),
            ),
          ),
          GoRoute(
            path: '/owner/reports',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('Reports Coming Soon in Phase 2')),
            ),
          ),
          GoRoute(
            path: '/owner/menu',
            builder: (_, __) => const BoatOwnerMenuScreen(),
          ),
          GoRoute(
            path: '/owner/profile',
            builder: (_, __) => const BoatOwnerProfileScreen(),
          ),
          GoRoute(
            path: '/owner/documents',
            builder: (_, __) => const DocumentDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/documents/list',
            builder: (_, state) {
              final type = state.uri.queryParameters['type'];
              final crewId = state.uri.queryParameters['crewId'];
              return DocumentListScreen(
                documentType: type,
                crewMemberId: crewId,
              );
            },
          ),
          GoRoute(
            path: '/owner/documents/details/:id',
            builder: (_, state) {
              final id = state.pathParameters['id'] ?? '';
              return DocumentDetailScreen(documentId: id);
            },
          ),
          GoRoute(
            path: '/owner/documents/add',
            builder: (_, state) {
              final crewId = state.uri.queryParameters['crewId'];
              final renewId = state.uri.queryParameters['renewId'];
              return AddDocumentScreen(
                crewId: crewId,
                renewId: renewId,
              );
            },
          ),
          GoRoute(
            path: '/owner/documents/crew',
            builder: (_, __) => const CrewDocumentsScreen(),
          ),
          GoRoute(
            path: '/owner/documents/crew/:crewMemberId/upload',
            builder: (_, state) {
              final id = state.pathParameters['crewMemberId'] ?? '';
              return UploadCrewProofScreen(crewMemberId: id);
            },
          ),
          GoRoute(
            path: '/owner/financial',
            builder: (_, __) => const FinancialDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/financial/voyages',
            builder: (_, __) => const FinancialVoyageListScreen(),
          ),
          GoRoute(
            path: '/owner/financial/voyages/:id',
            builder: (_, state) {
              final id = state.pathParameters['id'] ?? '';
              final tabIndexStr = state.uri.queryParameters['tab'];
              final tabIndex = int.tryParse(tabIndexStr ?? '0') ?? 0;
              return FinancialVoyageSummaryScreen(voyageId: id, initialTab: tabIndex);
            },
          ),
          GoRoute(
            path: '/owner/management',
            builder: (_, __) => const BoatOwnerManagementScreen(),
          ),
          GoRoute(
            path: '/owner/management/crew/add',
            builder: (_, __) => const BoatOwnerCrewForm(),
          ),
          GoRoute(
            path: '/owner/management/crew/edit/:id',
            builder: (_, s) => BoatOwnerCrewForm(crewId: s.pathParameters['id']),
          ),
          GoRoute(
            path: '/owner/my-boats',
            builder: (_, __) => const BoatOwnerBoatsScreen(),
          ),
          GoRoute(
            path: '/owner/my-boats/add',
            builder: (_, __) => const BoatFormScreen(),
          ),
          GoRoute(
            path: '/owner/my-boats/edit/:id',
            builder: (_, s) => BoatFormScreen(boatId: s.pathParameters['id']),
          ),
          GoRoute(
            path: '/owner/bills',
            builder: (_, __) => const BoatOwnerBillListScreen(),
          ),
          GoRoute(
            path: '/owner/bills/:id',
            builder: (_, s) =>
                BillDetailScreen(billId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/ledger',
            builder: (_, __) => const BoatOwnerLedgerScreen(),
          ),
          GoRoute(
            path: '/owner/ledger/boat/:boatId',
            builder: (_, s) =>
                BoatBalanceScreen(boatId: s.pathParameters['boatId']!),
          ),
          GoRoute(
            path: '/owner/location',
            builder: (_, __) => const FishingLocationScreen(),
          ),
          GoRoute(
            path: '/owner/fishing-grounds',
            builder: (_, __) => const FishingGroundHistoryScreen(),
          ),
          GoRoute(
            path: '/owner/fishing',
            builder: (_, __) => const BoatOwnerFishingScreen(),
          ),
          GoRoute(
            path: '/owner/fishing/hauls/new',
            builder: (_, s) => BoatOwnerHaulForm(voyageId: s.uri.queryParameters['voyageId']!),
          ),
          GoRoute(
            path: '/owner/fishing/hauls/:id',
            builder: (_, s) => BoatOwnerHaulDashboard(haulId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/fishing/hauls/:id/summary',
            builder: (_, s) => BoatOwnerHaulSummary(haulId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/fishing/hauls/:id/catches/new',
            builder: (_, s) => BoatOwnerCatchForm(haulId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/owner/fishing/hauls/history',
            builder: (_, s) => GpsTrackHistoryScreen(voyageId: s.uri.queryParameters['voyageId']!),
          ),
          GoRoute(
            path: '/owner/gps-tracks',
            builder: (_, __) => const GpsTrackAllScreen(),
          ),
          GoRoute(
            path: '/owner/gps-tracks/voyage/:voyageId',
            builder: (_, s) => GpsTrackVoyageDetailScreen(
              voyageId: s.pathParameters['voyageId']!,
            ),
          ),
          GoRoute(
            path: '/owner/tracking',
            builder: (_, __) => const FishPriceAnalyticsScreen(),
          ),
          GoRoute(
            path: '/owner/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
        ],
      ),

      // ── Fish Buyer shell ─────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _buyerShellKey,
        builder: (context, state, child) =>
            _BuyerShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/buyer/dashboard',
            builder: (_, __) => const FishBuyerDashboard(),
          ),
          GoRoute(
            path: '/buyer/fish-manage',
            builder: (_, __) => const FishListScreen(),
          ),
          GoRoute(
            path: '/buyer/bills',
            builder: (_, __) => const FishBuyerBillScreen(tabIndex: 1),
          ),
          GoRoute(
            path: '/buyer/bills/new',
            builder: (_, __) => const FishBuyerBillScreen(tabIndex: 0),
          ),
          GoRoute(
            path: '/buyer/profile',
            builder: (_, __) => const BoatOwnerProfileScreen(),
          ),
          GoRoute(
            path: '/buyer/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
        ],
      ),

      // ── Staff shell ──────────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _staffShellKey,
        builder: (context, state, child) =>
            _StaffShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/staff/dashboard',
            builder: (_, __) => const StaffDashboard(),
          ),
          GoRoute(
            path: '/staff/boats',
            builder: (_, __) => const BoatListScreen(),
          ),
          GoRoute(
            path: '/staff/bills',
            builder: (_, __) => const BillingFormScreen(tabIndex: 1),
          ),
          GoRoute(
            path: '/staff/bills/new',
            builder: (_, __) => const BillingFormScreen(tabIndex: 0),
          ),
          GoRoute(
            path: '/staff/bills/:id',
            builder: (_, s) =>
                BillDetailScreen(billId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/staff/tracking',
            builder: (_, __) => const FishPriceAnalyticsScreen(),
          ),
          GoRoute(
            path: '/staff/profile',
            builder: (_, __) => const BoatOwnerProfileScreen(),
          ),
          GoRoute(
            path: '/staff/change-password',
            builder: (_, __) => const ChangePasswordScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
          ],
        ),
      ),
    ),
  );
  return _routerInstance!;
});

// ── Shell widgets ─────────────────────────────────────────────────────────────

const _adminRoutes = [
  '/admin/dashboard',
  '/admin/harbours',
  '/admin/users',
  '/admin/packages',
  '/admin/more',
];

class _AdminShell extends StatelessWidget {
  final String location;
  final Widget child;
  const _AdminShell({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    // Find the best-matching route index. Longer prefix wins.
    int navIndex = 0;
    int bestLen = 0;
    for (int i = 0; i < _adminRoutes.length; i++) {
      final r = _adminRoutes[i];
      if (location.startsWith(r) && r.length > bestLen) {
        bestLen = r.length;
        navIndex = i;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: FishMarketNavBar(
        role: 'SUPER_ADMIN',
        currentIndex: navIndex,
        onTap: (idx) => context.go(_adminRoutes[idx]),
        onBillTap: () {},
      ),
    );
  }
}

// ── Agent nav routes ──────────────────────────────────────────────────────────
const _agentRoutes = [
  '/agent/dashboard',
  '/agent/boats',
  '/agent/bills',
  '/agent/tracking',
  '/agent/profile',
];

class _AgentShell extends StatelessWidget {
  final String location;
  final Widget child;
  const _AgentShell({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    int navIndex = 0;
    int bestLen = 0;
    for (int i = 0; i < _agentRoutes.length; i++) {
      final r = _agentRoutes[i];
      if (location.startsWith(r) && r.length > bestLen) {
        bestLen = r.length;
        navIndex = i;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: FishMarketNavBar(
        role: 'COMMISSION_AGENT',
        currentIndex: navIndex,
        onTap: (idx) => context.go(_agentRoutes[idx]),
        onBillTap: () => context.go('/agent/bills'),
      ),
    );
  }
}

// ── Owner nav routes ──────────────────────────────────────────────────────────
const _ownerRoutes = [
  '/owner/dashboard',
  '/owner/voyages',
  '/owner/fishing',
  '/owner/financial',
  '/owner/menu',
];

class _OwnerShell extends StatelessWidget {
  final String location;
  final Widget child;
  const _OwnerShell({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    int navIndex = 0;
    int bestLen = 0;
    for (int i = 0; i < _ownerRoutes.length; i++) {
      final r = _ownerRoutes[i];
      if (location.startsWith(r) && r.length > bestLen) {
        bestLen = r.length;
        navIndex = i;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: FishMarketNavBar(
        role: 'BOAT_OWNER',
        currentIndex: navIndex,
        onTap: (idx) => context.go(_ownerRoutes[idx]),
        onBillTap: () => context.go('/owner/bills'),
      ),
    );
  }
}

// ── Buyer nav routes ──────────────────────────────────────────────────────────
const _buyerRoutes = [
  '/buyer/dashboard',
  '/buyer/fish-manage',
  '/buyer/bills',
  '/buyer/profile',
];

class _BuyerShell extends StatelessWidget {
  final String location;
  final Widget child;
  const _BuyerShell({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    int navIndex = 0;
    int bestLen = 0;
    for (int i = 0; i < _buyerRoutes.length; i++) {
      final r = _buyerRoutes[i];
      if (location.startsWith(r) && r.length > bestLen) {
        bestLen = r.length;
        navIndex = i;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: FishMarketNavBar(
        role: 'FISH_BUYER',
        currentIndex: navIndex,
        onTap: (idx) => context.go(_buyerRoutes[idx]),
        onBillTap: () => context.go('/buyer/bills/new'),
      ),
    );
  }
}

// ── Staff nav routes ──────────────────────────────────────────────────────────
const _staffRoutes = ['/staff/dashboard', '/staff/bills', '/staff/profile'];

class _StaffShell extends StatelessWidget {
  final String location;
  final Widget child;
  const _StaffShell({required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    int navIndex = 0;
    int bestLen = 0;
    for (int i = 0; i < _staffRoutes.length; i++) {
      final r = _staffRoutes[i];
      if (location.startsWith(r) && r.length > bestLen) {
        bestLen = r.length;
        navIndex = i;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: FishMarketNavBar(
        role: 'STAFF',
        currentIndex: navIndex,
        onTap: (idx) => context.go(_staffRoutes[idx]),
        onBillTap: () => context.go('/staff/bills/new'),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _defaultRouteForRole(String role) {
  return switch (role) {
    'SUPER_ADMIN' => '/admin/dashboard',
    'COMMISSION_AGENT' => '/agent/dashboard',
    'BOAT_OWNER' => '/owner/dashboard',
    'FISH_BUYER' => '/buyer/dashboard',
    'STAFF' => '/staff/dashboard',
    _ => '/login',
  };
}

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(pinProvider, (_, __) => notifyListeners());
  }
}
