#include "include/flutter_local_push_connectivity/flutter_local_push_connectivity_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_local_push_connectivity_plugin.h"

void FlutterLocalPushConnectivityPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_local_push_connectivity::FlutterLocalPushConnectivityPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
