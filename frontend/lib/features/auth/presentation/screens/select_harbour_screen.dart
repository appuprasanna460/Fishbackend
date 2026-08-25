import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class HarbourItem {
  final String id;
  final String name;
  const HarbourItem({required this.id, required this.name});

  factory HarbourItem.fromJson(Map<String, dynamic> json) => HarbourItem(
        id: json['_id'] as String,
        name: json['name'] as String,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _harboursProvider =
    FutureProvider.autoDispose<List<HarbourItem>>((ref) async {
  final dio = ref.read(dioClientProvider).dio;
  final response = await dio.get(ApiConstants.harbours);
  final data = response.data['data'] as List? ?? [];
  return data
      .map((e) => HarbourItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class SelectHarbourScreen extends ConsumerStatefulWidget {
  const SelectHarbourScreen({super.key});

  @override
  ConsumerState<SelectHarbourScreen> createState() =>
      _SelectHarbourScreenState();
}

class _SelectHarbourScreenState extends ConsumerState<SelectHarbourScreen>
    with SingleTickerProviderStateMixin {
  HarbourItem? _selected;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a harbour to continue')),
      );
      return;
    }
    context.push(
      '/register',
      extra: {'harbourId': _selected!.id, 'harbourName': _selected!.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final harboursAsync = ref.watch(_harboursProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradient top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── App Bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                     IconButton(
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  },
  icon: const Icon(Icons.arrow_back, color: Colors.white),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
),
                      Expanded(
                        child: Text(
                          'Select Your Harbour',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.anchor_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  'Which harbour are you operating from?',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ── Card ────────────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: harboursAsync.when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_rounded,
                                      size: 48,
                                      color: AppColors.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Could not load harbours.\nPlease check your connection.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        ref.invalidate(_harboursProvider),
                                    icon:
                                        const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                            data: (harbours) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AVAILABLE HARBOURS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: harbours.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No harbours available.\nContact your administrator.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                                color:
                                                    AppColors.textSecondary),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: harbours.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (ctx, i) {
                                            final h = harbours[i];
                                            final isSelected =
                                                _selected?.id == h.id;
                                            return _HarbourTile(
                                              harbour: h,
                                              isSelected: isSelected,
                                              onTap: () => setState(
                                                  () => _selected = h),
                                            );
                                          },
                                        ),
                                ),
                                if (_selected != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withOpacity(0.07),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.anchor_rounded,
                                            color: AppColors.primary,
                                            size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _selected!.name,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primary,
                                            size: 18),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton.icon(
                                    onPressed: _onNext,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(27)),
                                    ),
                                    icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white),
                                    label: Text(
                                      'Next',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Harbour Tile ─────────────────────────────────────────────────────────────

class _HarbourTile extends StatelessWidget {
  final HarbourItem harbour;
  final bool isSelected;
  final VoidCallback onTap;

  const _HarbourTile({
    required this.harbour,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                harbour.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.anchor_rounded,
                  color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}
