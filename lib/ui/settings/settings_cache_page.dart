import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/osm/osm_territory_cacher.dart';
import 'package:plante/outside/off/off_cacher.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/settings/settings_buttons.dart';

class SettingsCachePage extends PagePlante {
  const SettingsCachePage({Key? key}) : super(key: key);

  @override
  _SettingsCachePageState createState() => _SettingsCachePageState();
}

class _SettingsCachePageState extends PageStatePlante<SettingsCachePage> {
  final _osmCacher = GetIt.I.get<OsmTerritoryCacher>();
  final _offCacher = GetIt.I.get<OffCacher>();
  final _mapExtraProperties = GetIt.I.get<MapExtraPropertiesCacher>();

  _SettingsCachePageState() : super('SettingsCachePage');

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: [
          HeaderPlante(
              title: Text(context.strings.settings_cache_page_title,
                  style: TextStyles.pageTitle),
              leftAction: const FabPlante.backBtnPopOnClick()),
          Column(children: [
            SettingsGeneralButton(
                onTap: _clearMapCacheAndRestart,
                text: context
                    .strings.settings_cache_page_clear_map_cache_and_exit),
          ]),
        ]))));
  }

  void _clearMapCacheAndRestart() async {
    try {
      await _osmCacher.deleteDatabase();
      await _offCacher.deleteDatabase();
      await _mapExtraProperties.deleteDatabase();
    } catch (e) {
      Log.e('Clear map cache error', ex: e);
    }
    exit(0);
  }
}
