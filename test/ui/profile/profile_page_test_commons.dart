import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/contributions/user_contributions_manager.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/products/contributed_by_user_products_storage.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/products/viewed_products_storage.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_settings.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_contributions_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

class ProfilePageTestCommons {
  static const avatarId = FakeUserAvatarManager.DEFAULT_AVATAR_ID;
  static final imagePath =
      Uri.file(File('./test/assets/img.jpg').absolute.path);
  late FakeAnalytics analytics;
  late FakeUserParamsController userParamsController;
  late FakeUserAvatarManager userAvatarManager;
  late FakeProductsObtainer productsObtainer;
  late ViewedProductsStorage viewedProductsStorage;
  late ContributedByUserProductsStorage contributedByUserProductsStorage;
  late FakeUserContributionsManager userContributionsManager;

  ProfilePageTestCommons._();

  static Future<ProfilePageTestCommons> create() async {
    final instance = ProfilePageTestCommons._();
    await instance._initAsync();
    return instance;
  }

  Future<void> _initAsync() async {
    await GetIt.I.reset();

    analytics = FakeAnalytics();
    userParamsController = FakeUserParamsController();
    userAvatarManager = FakeUserAvatarManager(userParamsController);
    userContributionsManager = FakeUserContributionsManager();

    GetIt.I.registerSingleton<Analytics>(analytics);
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    GetIt.I.registerSingleton<UserAvatarManager>(userAvatarManager);
    GetIt.I.registerSingleton<Settings>(FakeSettings());
    GetIt.I
        .registerSingleton<SysLangCodeHolder>(SysLangCodeHolder.inited('en'));
    GetIt.I.registerSingleton<Backend>(FakeBackend());
    GetIt.I.registerSingleton<UserReportsMaker>(MockUserReportsMaker());
    productsObtainer = FakeProductsObtainer();
    GetIt.I.registerSingleton<ProductsObtainer>(productsObtainer);
    viewedProductsStorage = ViewedProductsStorage();
    GetIt.I.registerSingleton<ViewedProductsStorage>(viewedProductsStorage);
    contributedByUserProductsStorage = ContributedByUserProductsStorage();
    GetIt.I.registerSingleton<ContributedByUserProductsStorage>(
        contributedByUserProductsStorage);
    GetIt.I
        .registerSingleton<UserContributionsManager>(userContributionsManager);
  }
}
