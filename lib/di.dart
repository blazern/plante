import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/user_params_auto_wiper.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/model/location_controller.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/osm/open_street_map.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/photos_taker.dart';

import 'outside/http_client.dart';

void initDI() {
  GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(
      RouteObserver<ModalRoute>());
  GetIt.I.registerSingleton<UserParamsController>(UserParamsController());
  GetIt.I.registerSingleton<LocationController>(LocationController());
  GetIt.I.registerSingleton<OpenStreetMap>(OpenStreetMap());
  GetIt.I.registerSingleton<GoogleAuthorizer>(GoogleAuthorizer());
  GetIt.I.registerSingleton<HttpClient>(HttpClient());
  GetIt.I.registerSingleton<PhotosTaker>(PhotosTaker());
  GetIt.I.registerSingleton<Backend>(
      Backend(GetIt.I.get<UserParamsController>(), GetIt.I.get<HttpClient>()));
  GetIt.I.registerSingleton<UserParamsAutoWiper>(UserParamsAutoWiper(
      GetIt.I.get<Backend>(), GetIt.I.get<UserParamsController>()));
  GetIt.I.registerSingleton<OffApi>(OffApi());
  GetIt.I.registerSingleton<ProductsManager>(
      ProductsManager(GetIt.I.get<OffApi>(), GetIt.I.get<Backend>()));
}
