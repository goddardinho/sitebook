import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:sitebook_flutter/shared/services/recreation_gov_api_service.dart';
import 'package:sitebook_flutter/features/credentials/services/credential_storage_service.dart';
import 'package:sitebook_flutter/shared/services/reservation_service.dart';
import 'package:sitebook_flutter/features/credentials/models/reservation_credential.dart';

import 'reservation_service_simple_test.mocks.dart';

// Generate mocks
@GenerateMocks([RecreationGovApiService, CredentialStorageService])
void main() {
  group('ReservationService Simple Tests', () {
    late ReservationService reservationService;
    late MockRecreationGovApiService mockApiService;
    late MockCredentialStorageService mockCredentialService;

    setUp(() {
      mockApiService = MockRecreationGovApiService();
      mockCredentialService = MockCredentialStorageService();

      reservationService = ReservationService(
        apiService: mockApiService,
        credentialService: mockCredentialService,
      );
    });

    group('Basic Functionality', () {
      test('should validate credentials successfully', () async {
        // Mock credential storage
        final mockCredentials = [
          ReservationCredential(
            id: 'rec_gov_1',
            name: 'Recreation.gov',
            url: 'https://recreation.gov',
            username: 'testuser@example.com',
            password: 'testpass123',
          ),
        ];

        when(
          mockCredentialService.loadCredentials(),
        ).thenAnswer((_) async => mockCredentials);

        // Test credential validation
        final hasValidCredentials = await reservationService
            .hasValidCredentials();

        expect(hasValidCredentials, isTrue);
        verify(mockCredentialService.loadCredentials()).called(1);
      });

      test('should handle missing credentials', () async {
        when(
          mockCredentialService.loadCredentials(),
        ).thenAnswer((_) async => []);

        final hasValidCredentials = await reservationService
            .hasValidCredentials();

        expect(hasValidCredentials, isFalse);
      });
    });

    group('Reservation Retrieval', () {
      test('should get user reservations successfully', () async {
        // Mock credentials
        final mockCredentials = [
          ReservationCredential(
            id: 'rec_gov_1',
            name: 'Recreation.gov',
            url: 'https://recreation.gov',
            username: 'testuser@example.com',
            password: 'testpass123',
          ),
        ];

        when(
          mockCredentialService.loadCredentials(),
        ).thenAnswer((_) async => mockCredentials);

        final mockReservations = [
          ReservationResponse(
            reservationId: 'RES001',
            confirmationCode: 'CONF001',
            status: 'confirmed',
            facilityId: 'FAC001',
            facilityName: 'Yellowstone NP',
            campsiteId: 'SITE001',
            campsiteName: 'Loop A Site 1',
            startDate: '2024-07-15',
            endDate: '2024-07-17',
            nights: 2,
            totalCost: 120.0,
            taxes: 8.0,
            fees: 12.0,
            customerEmail: 'test@example.com',
            customerName: 'Test User',
            feeBreakdown: [],
            createdAt: DateTime.now(),
          ),
        ];

        when(
          mockApiService.getUserReservations(any),
        ).thenAnswer((_) async => mockReservations);

        final result = await reservationService.getUserReservations();

        expect(result, hasLength(1));
        expect(
          result.first.id,
          contains('RES001'),
        ); // The mapping might change the ID format

        verify(mockApiService.getUserReservations(any)).called(1);
      });

      test('should handle API errors gracefully', () async {
        // Mock credentials
        final mockCredentials = [
          ReservationCredential(
            id: 'rec_gov_1',
            name: 'Recreation.gov',
            url: 'https://recreation.gov',
            username: 'testuser@example.com',
            password: 'testpass123',
          ),
        ];

        when(
          mockCredentialService.loadCredentials(),
        ).thenAnswer((_) async => mockCredentials);

        when(
          mockApiService.getUserReservations(any),
        ).thenThrow(Exception('API unavailable'));

        expect(() => reservationService.getUserReservations(), throwsException);
      });
    });

    group('Service Integration', () {
      test('should create service with dependencies', () {
        expect(reservationService, isNotNull);
        // Basic smoke test that service initializes
      });

      test('should handle caching appropriately', () async {
        // Mock credentials
        final mockCredentials = [
          ReservationCredential(
            id: 'rec_gov_1',
            name: 'Recreation.gov',
            url: 'https://recreation.gov',
            username: 'testuser@example.com',
            password: 'testpass123',
          ),
        ];

        when(
          mockCredentialService.loadCredentials(),
        ).thenAnswer((_) async => mockCredentials);

        final mockReservations = [
          ReservationResponse(
            reservationId: 'RES001',
            confirmationCode: 'CONF001',
            status: 'confirmed',
            facilityId: 'FAC001',
            facilityName: 'Test Park',
            campsiteId: 'SITE001',
            campsiteName: 'Site 1',
            startDate: '2024-07-15',
            endDate: '2024-07-17',
            nights: 2,
            totalCost: 100.0,
            taxes: 5.0,
            fees: 10.0,
            customerEmail: 'test@example.com',
            customerName: 'Test User',
            feeBreakdown: [],
            createdAt: DateTime.now(),
          ),
        ];

        when(
          mockApiService.getUserReservations(any),
        ).thenAnswer((_) async => mockReservations);

        // First call should hit the API
        final result1 = await reservationService.getUserReservations();

        // Second call within cache window should use cache
        final result2 = await reservationService.getUserReservations();

        expect(result1, hasLength(1));
        expect(result2, hasLength(1));
        expect(result1.first.id, equals(result2.first.id));

        // Should only be called once due to 15-minute caching
        verify(mockApiService.getUserReservations(any)).called(1);
      });
    });
  });
}
