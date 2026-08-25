import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedAppLang = 'English'; // தமிழ், English, Hindi
  String _primaryVoiceLang = 'Tamil';
  String _secondaryVoiceLang = 'English';
  bool _autoDetectLanguage = true;

  final List<String> _languages = ['தமிழ்', 'English', 'Hindi'];
  final List<String> _voiceLanguages = ['Tamil', 'English', 'Hindi', 'Telugu', 'Kannada', 'Malayalam'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Language Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Language Card
            _buildCard(
              title: 'APP LANGUAGE',
              icon: Icons.language_rounded,
              child: Column(
                children: _languages.map((lang) {
                  final isSelected = _selectedAppLang == lang;
                  return RadioListTile<String>(
                    title: Text(
                      lang,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    value: lang,
                    groupValue: _selectedAppLang,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedAppLang = val);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Voice Language Card
            _buildCard(
              title: 'VOICE ASSISTANCE LANGUAGE',
              icon: Icons.record_voice_over_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select languages for voice announcements, voice entries, and audio updates.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _primaryVoiceLang,
                    decoration: const InputDecoration(
                      labelText: 'Primary Voice Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _voiceLanguages
                        .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _primaryVoiceLang = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _secondaryVoiceLang,
                    decoration: const InputDecoration(
                      labelText: 'Secondary Voice Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _voiceLanguages
                        .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _secondaryVoiceLang = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Translation Settings
            _buildCard(
              title: 'TRANSLATION PREFERENCES',
              icon: Icons.translate_rounded,
              child: SwitchListTile(
                title: Text(
                  'Auto-Detect Voice Language',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Automatically detect spoken language during speech-to-text inputs.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                value: _autoDetectLanguage,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _autoDetectLanguage = val);
                },
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Save Preferences',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Language preferences updated successfully!'),
                      backgroundColor: Color(0xFF2ECC71),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
