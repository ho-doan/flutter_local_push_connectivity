#include "include/flutter_push_connectivity/flutter_push_connectivity_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_push_connectivity_plugin.h"

void FlutterPushConnectivityPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_push_connectivity::FlutterPushConnectivityPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
