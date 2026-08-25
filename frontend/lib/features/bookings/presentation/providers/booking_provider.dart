// lib/features/bookings/presentation/providers/booking_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/secure_storage.dart';
import '../../domain/entities/booking_entity.dart';
import '../../../boats/domain/entities/boat_entity.dart';

// State
class BookingState {
  final List<BookingEntity> myBookings;
  final List<BookingEntity> allBookings;
  final List<BoatEntity> myBookedBoats;
  final bool isLoading;
  final String? error;
  final Map<String, bool> bookingStatus;
  final Map<String, BookingEntity> bookingDetails;

  BookingState({
    List<BookingEntity>? myBookings,
    List<BookingEntity>? allBookings,
    List<BoatEntity>? myBookedBoats,
    this.isLoading = false,
    this.error,
    Map<String, bool>? bookingStatus,
    Map<String, BookingEntity>? bookingDetails,
  }) : myBookings = myBookings ?? const [],
       allBookings = allBookings ?? const [],
       myBookedBoats = myBookedBoats ?? const [], // ✅ Ensure never null
       bookingStatus = bookingStatus ?? const {},
       bookingDetails = bookingDetails ?? const {};

  BookingState copyWith({
    List<BookingEntity>? myBookings,
    List<BookingEntity>? allBookings,
    List<BoatEntity>? myBookedBoats,
    bool? isLoading,
    String? error,
    Map<String, bool>? bookingStatus,
    Map<String, BookingEntity>? bookingDetails,
  }) {
    return BookingState(
      myBookings: myBookings ?? this.myBookings,
      allBookings: allBookings ?? this.allBookings,
      myBookedBoats: myBookedBoats ?? this.myBookedBoats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      bookingDetails: bookingDetails ?? this.bookingDetails,
    );
  }

  static BookingState initial() {
    return BookingState();
  }
}

// Provider
class BookingProvider extends StateNotifier<BookingState> {
  final Dio _dio;

  BookingProvider(this._dio) : super(BookingState.initial());

  /// ✅ Load MY bookings (for "My Booked Boats" tab)
  Future<void> loadMyBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await SecureStorage.getToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.bookings}/my-bookings',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        final myBookings = data.map((e) => BookingEntity.fromJson(e)).toList();

        print('📊 My Bookings: ${myBookings.length}');

        state = state.copyWith(
          myBookings: myBookings,
          isLoading: false,
          error: null,
        );
        print('✅ Loaded ${myBookings.length} MY bookings');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to load my bookings',
          myBookings: const [],
        );
      }
    } catch (e) {
      print('❌ Error loading my bookings: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        myBookings: const [],
      );
    }
  }

  /// ✅ Load ALL bookings (for "Available Boats" tab)
  Future<void> loadAllBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await SecureStorage.getToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.bookings}/all-for-display',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        final allBookings = data.map((e) => BookingEntity.fromJson(e)).toList();

        final statusMap = <String, bool>{};
        final detailsMap = <String, BookingEntity>{};
        for (final booking in allBookings) {
          print(
            '📌 Booking: ${booking.bookingNumber} -> BoatID: ${booking.boatId} -> Agent: ${booking.agentName}',
          );
          statusMap[booking.boatId] = true;
          detailsMap[booking.boatId] = booking;
        }

        print('📊 All Booking Status Map: $statusMap');

        state = state.copyWith(
          allBookings: allBookings,
          isLoading: false,
          error: null,
          bookingStatus: statusMap,
          bookingDetails: detailsMap,
        );
        print('✅ Loaded ${allBookings.length} ALL bookings');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to load all bookings',
          allBookings: const [],
          bookingStatus: const {},
          bookingDetails: const {},
        );
      }
    } catch (e) {
      print('❌ Error loading all bookings: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        allBookings: const [],
        bookingStatus: const {},
        bookingDetails: const {},
      );
    }
  }

  /// ✅ Load boats booked by the current agent (for dropdown)
  Future<void> loadMyBookedBoats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await SecureStorage.getToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.bookings}/my-booked-boats',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];

        // ✅ Handle null/empty data safely
        if (data.isEmpty) {
          state = state.copyWith(
            myBookedBoats: const [],
            isLoading: false,
            error: null,
          );
          print('✅ No booked boats found');
          return;
        }

        final myBookedBoats = <BoatEntity>[];
        for (final item in data) {
          try {
            Map<String, dynamic> boatData;

            // Handle nested boatId format
            if (item is Map<String, dynamic> &&
                item.containsKey('boatId') &&
                item['boatId'] is Map) {
              boatData = Map<String, dynamic>.from(item['boatId']);
            } else if (item is Map<String, dynamic>) {
              boatData = Map<String, dynamic>.from(item);
            } else {
              continue;
            }

            // Add _id to id if needed
            if (boatData.containsKey('_id') && !boatData.containsKey('id')) {
              boatData['id'] = boatData['_id'];
            }

            final boat = BoatEntity.fromJson(boatData);
            myBookedBoats.add(boat);
          } catch (e) {
            print('⚠️ Error parsing boat: $e');
          }
        }

        print('📊 My Booked Boats: ${myBookedBoats.length}');

        state = state.copyWith(
          myBookedBoats: myBookedBoats,
          isLoading: false,
          error: null,
        );
        print('✅ Loaded ${myBookedBoats.length} booked boats');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to load booked boats',
          myBookedBoats: const [],
        );
      }
    } catch (e) {
      print('❌ Error loading booked boats: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        myBookedBoats: const [],
      );
    }
  }

  /// Book a boat
  Future<BookingEntity?> bookBoat(String boatId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await SecureStorage.getToken();

      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.bookings}',
        data: {'boatId': boatId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 409) {
        print('ℹ️ Boat already booked');
        await loadAllBookings();
        await loadMyBookings();
        await loadMyBookedBoats();
        state = state.copyWith(isLoading: false, error: null);
        return null;
      }

      if (response.statusCode == 201) {
        final booking = BookingEntity.fromJson(response.data['data']);
        await loadAllBookings();
        await loadMyBookings();
        await loadMyBookedBoats();
        print('✅ Boat booked successfully: ${booking.bookingNumber}');
        return booking;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to book boat',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error booking boat: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Remove booking
  Future<bool> removeBooking(String bookingId, String boatId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await SecureStorage.getToken();

      final response = await _dio.delete(
        '${ApiConstants.baseUrl}${ApiConstants.bookings}/$bookingId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        await loadAllBookings();
        await loadMyBookings();
        await loadMyBookedBoats();
        print('✅ Booking removed successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to remove booking',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error removing booking: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Check if boat is booked (from ALL bookings)
  bool isBoatBooked(String boatId) {
    return state.bookingStatus[boatId] ?? false;
  }

  /// Get booking details for a boat (from ALL bookings)
  BookingEntity? getBookingDetails(String boatId) {
    return state.bookingDetails[boatId];
  }
}

// Provider instance
final bookingProvider = StateNotifierProvider<BookingProvider, BookingState>((
  ref,
) {
  final dio = DioClient().dio;
  return BookingProvider(dio);
});
