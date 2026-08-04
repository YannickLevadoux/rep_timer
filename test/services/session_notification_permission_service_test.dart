import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/session_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('remonte le statut accordé', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.granted,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    expect(
      await service.notificationPermissionStatus(),
      SessionNotificationPermissionStatus.granted,
    );
  });

  test('distingue le refus du refus définitif', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.denied,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    expect(
      await service.notificationPermissionStatus(),
      SessionNotificationPermissionStatus.denied,
    );
    platform.notificationStatus =
        SessionNotificationPermissionStatus.permanentlyDenied;
    expect(
      await service.notificationPermissionStatus(),
      SessionNotificationPermissionStatus.permanentlyDenied,
    );
  });

  test('la demande de notification ne demande jamais la batterie', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.denied,
      requestedNotificationStatus: SessionNotificationPermissionStatus.granted,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    expect(
      await service.requestNotificationPermission(),
      SessionNotificationPermissionStatus.granted,
    );
    expect(platform.notificationRequestCalls, 1);
    expect(platform.batteryRequestCalls, 0);
  });

  test('la demande batterie ne demande jamais la notification', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.denied,
      batteryStatus: BatteryOptimizationStatus.optimized,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    expect(
      await service.requestBatteryOptimizationExemption(),
      BatteryOptimizationStatus.exempt,
    );
    expect(platform.batteryRequestCalls, 1);
    expect(platform.notificationRequestCalls, 0);
  });

  test('ne redemande pas une notification déjà accordée', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.granted,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    await service.requestNotificationPermission();

    expect(platform.notificationRequestCalls, 0);
  });

  test('ne redemande pas une exemption déjà accordée', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.denied,
      batteryStatus: BatteryOptimizationStatus.exempt,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    await service.requestBatteryOptimizationExemption();

    expect(platform.batteryRequestCalls, 0);
  });

  test('convertit les erreurs de plateforme en états indisponibles', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.denied,
      throwOnCalls: true,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    expect(
      await service.notificationPermissionStatus(),
      SessionNotificationPermissionStatus.unavailable,
    );
    expect(
      await service.batteryOptimizationStatus(),
      BatteryOptimizationStatus.unavailable,
    );
    expect(await service.openNotificationSettings(), isFalse);
  });

  test("ouvre les réglages via l'abstraction injectable", () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.permanentlyDenied,
    );
    final service = SessionNotificationPermissionService(platform: platform);

    expect(await service.openNotificationSettings(), isTrue);
    expect(platform.openSettingsCalls, 1);
  });

  test('le Foreground Service ne demande aucune autorisation', () async {
    final platform = _FakePermissionPlatform(
      notificationStatus: SessionNotificationPermissionStatus.denied,
    );
    final notificationService = SessionNotificationService(
      permissionService: SessionNotificationPermissionService(
        platform: platform,
      ),
    );

    await notificationService.pin(
      data: const SessionNotificationPinData(
        baseMilliseconds: 0,
        pinEpochMillis: 0,
        isPlaying: true,
        isCountingDown: false,
        stepLabel: 'Exercice',
        nextStepLabel: 'Suivant',
        stepToken: 'token',
        notificationMode: NotificationMode.none,
        soundGoOffsetMilliseconds: 0,
      ),
      onPausePressed: () {},
      onSoundThreshold: (_) {},
      onTimedStepEnded: (_, _) {},
    );

    expect(platform.notificationRequestCalls, 0);
    expect(platform.batteryRequestCalls, 0);
    notificationService.dispose();
  });
}

class _FakePermissionPlatform implements SessionNotificationPermissionPlatform {
  _FakePermissionPlatform({
    required this.notificationStatus,
    this.requestedNotificationStatus,
    this.batteryStatus = BatteryOptimizationStatus.optimized,
    this.throwOnCalls = false,
  });

  SessionNotificationPermissionStatus notificationStatus;
  final SessionNotificationPermissionStatus? requestedNotificationStatus;
  BatteryOptimizationStatus batteryStatus;
  final bool throwOnCalls;
  int notificationRequestCalls = 0;
  int batteryRequestCalls = 0;
  int openSettingsCalls = 0;

  void _maybeThrow() {
    if (throwOnCalls) throw StateError('platform error');
  }

  @override
  void initialize() => _maybeThrow();

  @override
  Future<SessionNotificationPermissionStatus>
  notificationPermissionStatus() async {
    _maybeThrow();
    return notificationStatus;
  }

  @override
  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async {
    _maybeThrow();
    notificationRequestCalls++;
    notificationStatus = requestedNotificationStatus ?? notificationStatus;
    return notificationStatus;
  }

  @override
  Future<bool> openNotificationSettings() async {
    _maybeThrow();
    openSettingsCalls++;
    return true;
  }

  @override
  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async {
    _maybeThrow();
    return batteryStatus;
  }

  @override
  Future<void> requestBatteryOptimizationExemption() async {
    _maybeThrow();
    batteryRequestCalls++;
    batteryStatus = BatteryOptimizationStatus.exempt;
  }
}
