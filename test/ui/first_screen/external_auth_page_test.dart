import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/apple_user.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/outside/identity/google_user.dart';
import 'package:plante/ui/first_screen/external_auth_page.dart';

import '../../common_mocks.mocks.dart';
import '../../test_di_registry.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  late FakeAnalytics analytics;
  late MockGoogleAuthorizer googleAuthorizer;
  late MockAppleAuthorizer appleAuthorizer;
  late MockBackend backend;
  late FakeUserParamsController userParamsController;

  setUp(() async {
    googleAuthorizer = MockGoogleAuthorizer();
    appleAuthorizer = MockAppleAuthorizer();
    backend = MockBackend();
    analytics = FakeAnalytics();
    userParamsController = FakeUserParamsController();

    await TestDiRegistry.register((r) {
      r.register<GoogleAuthorizer>(googleAuthorizer);
      r.register<AppleAuthorizer>(appleAuthorizer);
      r.register<Backend>(backend);
      r.register<Analytics>(analytics);
      r.register<UserParamsController>(userParamsController);
    });

    when(backend.updateUserParams(any)).thenAnswer((_) async => Ok(true));
  });

  testWidgets('Google: successful Google Sign in', (WidgetTester tester) async {
    final googleUser = GoogleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    when(backend.loginOrRegister(googleIdToken: anyNamed('googleIdToken')))
        .thenAnswer((_) async => Ok(UserParams()));

    expect(analytics.allEvents(), equals([]));

    await tester.superPump(const ExternalAuthPage());

    await tester.tap(find.text('Google'));

    // We expect the Google name to be sent to the server
    final expectedParams = UserParams((e) => e.name = 'bob');
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    verify(backend.updateUserParams(expectedParams));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('google_auth_start'), isTrue);
    expect(analytics.wasEventSent('google_auth_success'), isTrue);
  });

  testWidgets('Google: not successful Google Sign in',
      (WidgetTester tester) async {
    when(googleAuthorizer.auth()).thenAnswer((_) async => null);

    await tester.superPump(const ExternalAuthPage());

    await tester.tap(find.text('Google'));
    expect(await userParamsController.getUserParams(), isNull);
    verifyNever(backend.updateUserParams(any));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('google_auth_start'), isTrue);
    expect(analytics.wasEventSent('google_auth_google_failure'), isTrue);
  });

  testWidgets('Google: not successful backend sign in',
      (WidgetTester tester) async {
    final googleUser = GoogleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    when(backend.loginOrRegister(googleIdToken: anyNamed('googleIdToken')))
        .thenAnswer((_) async => Err(BackendError.other()));

    expect(analytics.allEvents(), equals([]));

    await tester.superPump(const ExternalAuthPage());

    await tester.tap(find.text('Google'));
    expect(await userParamsController.getUserParams(), isNull);
    verifyNever(backend.updateUserParams(any));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('google_auth_start'), isTrue);
    expect(analytics.wasEventSent('auth_backend_failure'), isTrue);
  });

  testWidgets('Google: not successful backend params update',
      (WidgetTester tester) async {
    final googleUser = GoogleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    when(backend.loginOrRegister(googleIdToken: anyNamed('googleIdToken')))
        .thenAnswer((_) async => Ok(UserParams()));
    when(backend.updateUserParams(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    await tester.superPump(const ExternalAuthPage());

    await tester.tap(find.text('Google'));
    // Params were tried to be updated
    verify(backend.updateUserParams(any));
    // But params were not stored
    expect(await userParamsController.getUserParams(), isNull);
  });

  testWidgets('Apple: successful Apple Sign in', (WidgetTester tester) async {
    final appleUser = AppleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(appleAuthorizer.auth()).thenAnswer((_) async => appleUser);
    when(backend.loginOrRegister(
            appleAuthorizationCode: anyNamed('appleAuthorizationCode')))
        .thenAnswer((_) async => Ok(UserParams()));

    expect(analytics.allEvents(), equals([]));

    final context = await tester.superPump(const ExternalAuthPage());

    await tester
        .tap(find.text(context.strings.external_auth_page_continue_with_apple));

    // We expect the Apple name to be sent to the server
    final expectedParams = UserParams((e) => e.name = 'bob');
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    verify(backend.updateUserParams(expectedParams));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('apple_auth_start'), isTrue);
    expect(analytics.wasEventSent('apple_auth_success'), isTrue);
  });

  testWidgets('Apple: not successful Apple Sign in',
      (WidgetTester tester) async {
    when(appleAuthorizer.auth()).thenAnswer((_) async => null);

    final context = await tester.superPump(const ExternalAuthPage());

    await tester
        .tap(find.text(context.strings.external_auth_page_continue_with_apple));
    expect(await userParamsController.getUserParams(), isNull);
    verifyNever(backend.updateUserParams(any));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('apple_auth_start'), isTrue);
    expect(analytics.wasEventSent('apple_auth_apple_failure'), isTrue);
  });

  testWidgets('Apple: not successful backend sign in',
      (WidgetTester tester) async {
    final appleUser = AppleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(appleAuthorizer.auth()).thenAnswer((_) async => appleUser);
    when(backend.loginOrRegister(
            appleAuthorizationCode: anyNamed('appleAuthorizationCode')))
        .thenAnswer((_) async => Err(BackendError.other()));

    expect(analytics.allEvents(), equals([]));

    final context = await tester.superPump(const ExternalAuthPage());

    await tester
        .tap(find.text(context.strings.external_auth_page_continue_with_apple));
    expect(await userParamsController.getUserParams(), isNull);
    verifyNever(backend.updateUserParams(any));

    expect(analytics.allEvents().length, equals(2));
    expect(analytics.wasEventSent('apple_auth_start'), isTrue);
    expect(analytics.wasEventSent('auth_backend_failure'), isTrue);
  });

  testWidgets('Apple: not successful backend params update',
      (WidgetTester tester) async {
    final appleUser = AppleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(appleAuthorizer.auth()).thenAnswer((_) async => appleUser);
    when(backend.loginOrRegister(
            appleAuthorizationCode: anyNamed('appleAuthorizationCode')))
        .thenAnswer((_) async => Ok(UserParams()));
    when(backend.updateUserParams(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final context = await tester.superPump(const ExternalAuthPage());

    await tester
        .tap(find.text(context.strings.external_auth_page_continue_with_apple));
    // Params were tried to be updated
    verify(backend.updateUserParams(any));
    // But params were not stored
    expect(await userParamsController.getUserParams(), isNull);
  });
}
