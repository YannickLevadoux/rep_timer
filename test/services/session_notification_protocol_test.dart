import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';

void main() {
  test('le point de référence conserve ses données après sérialisation', () {
    const data = SessionNotificationPinData(
      stepLabel: 'Pause',
      nextStepLabel: 'Suivant : Groupe - Exercice',
      stepToken: 'session:1',
      notificationMode: NotificationMode.vibration,
      isPlaying: true,
      isCountingDown: true,
      baseMilliseconds: 30000,
      pinEpochMillis: 1234,
      soundGoOffsetMilliseconds: 2400,
    );

    final decoded = SessionNotificationPinData.fromWire(data.toWire());

    expect(decoded?.stepLabel, data.stepLabel);
    expect(decoded?.nextStepLabel, data.nextStepLabel);
    expect(decoded?.stepToken, data.stepToken);
    expect(decoded?.notificationMode, data.notificationMode);
    expect(decoded?.baseMilliseconds, data.baseMilliseconds);
  });

  test('les événements conservent leur type après sérialisation', () {
    const sound = SessionSoundThresholdReached('step-1');
    const end = SessionTimedStepEnded('step-1', NotificationMode.sound);

    expect(
      SessionNotificationEvent.fromWire(sound.toWire()),
      isA<SessionSoundThresholdReached>(),
    );
    final decodedEnd = SessionNotificationEvent.fromWire(end.toWire());
    expect(decodedEnd, isA<SessionTimedStepEnded>());
    expect(
      (decodedEnd as SessionTimedStepEnded).notificationMode,
      NotificationMode.sound,
    );
  });

  test('un message incomplet est rejeté', () {
    expect(SessionNotificationPinData.fromWire(<String, Object>{}), isNull);
    expect(
      SessionNotificationEvent.fromWire(<String, Object>{
        'event': 'timedStepEnded',
        'stepToken': 'step-1',
      }),
      isNull,
    );
  });
}
