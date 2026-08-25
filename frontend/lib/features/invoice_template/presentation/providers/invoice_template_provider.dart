// lib/features/invoice_template/presentation/providers/invoice_template_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/invoice_template_repository.dart';
import '../../domain/entities/invoice_template_entity.dart';

// ✅ Fixed: Use correct provider syntax
final invoiceTemplateProvider =
    StateNotifierProvider<InvoiceTemplateNotifier, InvoiceTemplateState>((ref) {
      return InvoiceTemplateNotifier(ref);
    });

class InvoiceTemplateState {
  final InvoiceTemplateEntity? template;
  final List<InvoiceTemplateEntity>? allTemplates;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  InvoiceTemplateState({
    this.template,
    this.allTemplates,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  InvoiceTemplateState copyWith({
    InvoiceTemplateEntity? template,
    List<InvoiceTemplateEntity>? allTemplates,
    bool? isLoading,
    String? error,
    bool? isSaving,
  }) {
    return InvoiceTemplateState(
      template: template ?? this.template,
      allTemplates: allTemplates ?? this.allTemplates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ✅ Fixed: Use Ref instead of Reader
class InvoiceTemplateNotifier extends StateNotifier<InvoiceTemplateState> {
  final Ref _ref;
  final InvoiceTemplateRepository _repository = InvoiceTemplateRepository();

  InvoiceTemplateNotifier(this._ref) : super(InvoiceTemplateState());

  Future<void> loadActiveTemplate() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final template = await _repository.getActiveTemplate();
      state = state.copyWith(template: template, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllTemplates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final templates = await _repository.getAllTemplates();
      state = state.copyWith(allTemplates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveTemplate(InvoiceTemplateEntity template) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final saved = await _repository.saveTemplate(template);
      // Refresh the list
      await loadAllTemplates();
      await loadActiveTemplate();
      state = state.copyWith(isSaving: false, template: saved);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTemplate(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteTemplate(id);
      await loadAllTemplates();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleTemplateStatus(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.toggleTemplateStatus(id);
      await loadAllTemplates();
      await loadActiveTemplate();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
