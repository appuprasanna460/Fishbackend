// lib/features/invoice_template/data/repositories/invoice_template_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/invoice_template_entity.dart';

class InvoiceTemplateRepository {
  final Dio _dio;

  InvoiceTemplateRepository() : _dio = DioClient().dio;

  // ✅ Get active template
  Future<InvoiceTemplateEntity> getActiveTemplate() async {
    try {
      final response = await _dio.get(ApiConstants.invoiceTemplatesActive);
      final data = response.data['data'];
      return InvoiceTemplateEntity.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _getDefaultTemplate();
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to load template');
    }
  }

  // ✅ Get all templates (Super Admin only)
  Future<List<InvoiceTemplateEntity>> getAllTemplates() async {
    try {
      final response = await _dio.get(ApiConstants.invoiceTemplatesAll);
      final dynamic responseData = response.data['data'];
      final List<dynamic> dataList;

      if (responseData is List) {
        dataList = responseData;
      } else if (responseData is Map<String, dynamic>) {
        // If the API incorrectly returns a single object, wrap it in a list
        dataList = [responseData];
      } else {
        dataList = [];
      }
      return dataList
          .map((e) => InvoiceTemplateEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load templates',
      );
    }
  }

  // ✅ Save template (Create or Update)
  Future<InvoiceTemplateEntity> saveTemplate(
    InvoiceTemplateEntity template,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.invoiceTemplates,
        data: template.toJson(),
      );
      return InvoiceTemplateEntity.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to save template');
    }
  }

  // ✅ Delete template
  Future<void> deleteTemplate(String id) async {
    try {
      final url = ApiConstants.invoiceTemplateById.replaceAll('{id}', id);
      await _dio.delete(url);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to delete template',
      );
    }
  }

  // ✅ Toggle template status (Activate/Deactivate)
  Future<void> toggleTemplateStatus(String id) async {
    try {
      final url = ApiConstants.invoiceTemplateToggle.replaceAll('{id}', id);
      await _dio.patch(url);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to toggle status');
    }
  }

  // ✅ Default template
  InvoiceTemplateEntity _getDefaultTemplate() {
    return InvoiceTemplateEntity(
      title: 'INVOICE',
      subtitle: 'Fish Market - Official Receipt',
      termsConditions:
          '1. Goods once sold will not be taken back.\n2. Payment must be made within 7 days.\n3. All disputes subject to local jurisdiction.',
      contactDetails: ContactDetails(
        phone: '+91 9876543210',
        email: 'contact@fishmarket.com',
        website: 'www.fishmarket.com',
      ),
      address: Address(
        street: '123, Fish Market Road',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400001',
        country: 'India',
      ),
      footer: 'Thank you for your business!',
      isActive: true,
    );
  }
}
