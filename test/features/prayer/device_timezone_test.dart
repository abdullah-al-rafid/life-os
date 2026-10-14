import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/prayer/domain/prayer_models.dart';
import 'package:life_os/features/prayer/presentation/prayer_providers.dart';

const _channel = MethodChannel('life_os/device_timezone');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('returns the IANA timezone supplied by Android', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          expect(call.method, 'getTimeZone');
          return 'Asia/Dhaka';
        });
    expect(await readDeviceTimezone(), 'Asia/Dhaka');
  });

  test('null timezone response becomes a typed failure', () async {
    _mockResponse(null);
    await expectLater(
      readDeviceTimezone(),
      throwsA(isA<DeviceTimezoneFailure>()),
    );
  });

  test('missing platform channel becomes a typed failure', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    await expectLater(
      readDeviceTimezone(),
      throwsA(isA<DeviceTimezoneFailure>()),
    );
  });

  test('platform channel failure becomes a typed failure', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          throw PlatformException(code: 'unsupported_timezone');
        });
    await expectLater(
      readDeviceTimezone(),
      throwsA(isA<DeviceTimezoneFailure>()),
    );
  });

  test('invalid timezone ID becomes a typed failure', () async {
    _mockResponse('Not a timezone');
    await expectLater(
      readDeviceTimezone(),
      throwsA(isA<DeviceTimezoneFailure>()),
    );
  });
}

void _mockResponse(Object? response) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async => response);
}
