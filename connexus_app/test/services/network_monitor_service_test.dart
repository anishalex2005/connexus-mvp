import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connexus_app/data/services/network_monitor_service.dart';
import 'package:connexus_app/domain/models/network_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks(<Type>[Connectivity])
import 'network_monitor_service_test.mocks.dart';

void main() {
  late NetworkMonitorService networkMonitorService;
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => <ConnectivityResult>[ConnectivityResult.wifi]);

    networkMonitorService = NetworkMonitorService(
      connectivity: mockConnectivity,
    );
  });

  tearDown(() async {
    await networkMonitorService.dispose();
    await connectivityController.close();
  });

  group('NetworkMonitorService', () {
    test('starts monitoring successfully', () async {
      await networkMonitorService.startMonitoring();

      expect(networkMonitorService.isMonitoring, isTrue);
      verify(mockConnectivity.checkConnectivity()).called(1);
      verify(mockConnectivity.onConnectivityChanged).called(1);
    });

    test('emits initial state on start', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
      );

      final List<NetworkState> states = <NetworkState>[];
      networkMonitorService.networkStateStream.listen(states.add);

      await networkMonitorService.startMonitoring();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states.isNotEmpty, isTrue);
      expect(states.last.status, NetworkStatus.wifi);
      expect(states.last.isConnected, isTrue);
    });

    test('detects WiFi connection correctly', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
      );

      await networkMonitorService.startMonitoring();

      expect(networkMonitorService.currentState.status, NetworkStatus.wifi);
      expect(networkMonitorService.currentState.isConnected, isTrue);
    });

    test('detects cellular connection correctly', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.mobile],
      );

      await networkMonitorService.startMonitoring();

      expect(
        networkMonitorService.currentState.status,
        NetworkStatus.cellular,
      );
      expect(networkMonitorService.currentState.isConnected, isTrue);
    });

    test('detects no connection correctly', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.none],
      );

      await networkMonitorService.startMonitoring();

      expect(
        networkMonitorService.currentState.status,
        NetworkStatus.disconnected,
      );
      expect(networkMonitorService.currentState.isConnected, isFalse);
    });

    test('emits change event when network type changes', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
      );

      await networkMonitorService.startMonitoring();

      final List<NetworkChangeEvent> changeEvents = <NetworkChangeEvent>[];
      networkMonitorService.networkChangeStream.listen(changeEvents.add);

      // Simulate network change to cellular.
      connectivityController
          .add(<ConnectivityResult>[ConnectivityResult.mobile]);

      // Wait for debounce.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(changeEvents.isNotEmpty, isTrue);
      final NetworkChangeEvent lastEvent = changeEvents.last;
      expect(lastEvent.changeType, NetworkChangeType.typeChanged);
      expect(lastEvent.currentState.status, NetworkStatus.cellular);
    });

    test('emits disconnected event when network is lost', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
      );

      await networkMonitorService.startMonitoring();

      final List<NetworkChangeEvent> changeEvents = <NetworkChangeEvent>[];
      networkMonitorService.networkChangeStream.listen(changeEvents.add);

      // Simulate network loss.
      connectivityController.add(<ConnectivityResult>[ConnectivityResult.none]);

      await Future<void>.delayed(const Duration(milliseconds: 600));

      final NetworkChangeEvent disconnectEvent = changeEvents.firstWhere(
        (NetworkChangeEvent e) =>
            e.changeType == NetworkChangeType.disconnected,
      );

      expect(disconnectEvent.currentState.isConnected, isFalse);
    });

    test('emits reconnected event when network is restored', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.none],
      );

      await networkMonitorService.startMonitoring();

      final List<NetworkChangeEvent> changeEvents = <NetworkChangeEvent>[];
      networkMonitorService.networkChangeStream.listen(changeEvents.add);

      // Simulate network restoration.
      connectivityController.add(<ConnectivityResult>[ConnectivityResult.wifi]);

      await Future<void>.delayed(const Duration(milliseconds: 600));

      final NetworkChangeEvent reconnectEvent = changeEvents.firstWhere(
        (NetworkChangeEvent e) => e.changeType == NetworkChangeType.reconnected,
      );

      expect(reconnectEvent.currentState.isConnected, isTrue);
    });

    test('stops monitoring correctly', () async {
      await networkMonitorService.startMonitoring();
      expect(networkMonitorService.isMonitoring, isTrue);

      await networkMonitorService.stopMonitoring();
      expect(networkMonitorService.isMonitoring, isFalse);
    });

    test('isSuitableForCalls returns correct value', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
      );

      await networkMonitorService.startMonitoring();

      expect(networkMonitorService.isSuitableForCalls, isTrue);
    });

    test('debounces rapid network changes', () async {
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => <ConnectivityResult>[ConnectivityResult.wifi],
      );

      await networkMonitorService.startMonitoring();

      final List<NetworkState> states = <NetworkState>[];
      networkMonitorService.networkStateStream.listen(states.add);

      states.clear();

      // Simulate rapid network changes.
      connectivityController
          .add(<ConnectivityResult>[ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      connectivityController.add(<ConnectivityResult>[ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      connectivityController
          .add(<ConnectivityResult>[ConnectivityResult.mobile]);

      // Wait for debounce to complete.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      // Should only have received the final state after debounce.
      expect(states.length, lessThanOrEqualTo(2));
    });
  });

  group('NetworkState', () {
    test('factory constructors work correctly', () {
      final NetworkState unknown = NetworkState.unknown();
      expect(unknown.status, NetworkStatus.unknown);
      expect(unknown.isConnected, isFalse);

      final NetworkState connected = NetworkState.connected(
        status: NetworkStatus.wifi,
        quality: NetworkQuality.excellent,
      );
      expect(connected.status, NetworkStatus.wifi);
      expect(connected.isConnected, isTrue);
      expect(connected.quality, NetworkQuality.excellent);

      final NetworkState disconnected = NetworkState.disconnected();
      expect(disconnected.status, NetworkStatus.disconnected);
      expect(disconnected.isConnected, isFalse);
    });

    test('isSuitableForCalls returns correct values', () {
      final NetworkState wifi = NetworkState.connected(
        status: NetworkStatus.wifi,
        quality: NetworkQuality.good,
      );
      expect(wifi.isSuitableForCalls, isTrue);

      final NetworkState poorWifi = NetworkState.connected(
        status: NetworkStatus.wifi,
        quality: NetworkQuality.poor,
      );
      expect(poorWifi.isSuitableForCalls, isFalse);

      final NetworkState disconnected = NetworkState.disconnected();
      expect(disconnected.isSuitableForCalls, isFalse);
    });

    test('hasNetworkTypeChanged detects type changes', () {
      final NetworkState wifi =
          NetworkState.connected(status: NetworkStatus.wifi);
      final NetworkState cellular =
          NetworkState.connected(status: NetworkStatus.cellular);
      final NetworkState disconnected = NetworkState.disconnected();

      expect(cellular.hasNetworkTypeChanged(wifi), isTrue);
      expect(wifi.hasNetworkTypeChanged(wifi), isFalse);
      expect(cellular.hasNetworkTypeChanged(disconnected), isFalse);
    });
  });
}
