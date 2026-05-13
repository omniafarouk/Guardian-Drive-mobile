//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

<<<<<<< HEAD
#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>
=======
#include <app_links/app_links_plugin_c_api.h>
>>>>>>> 9e5acd308a34305deef445040d0b5a4199af460a
#include <geolocator_windows/geolocator_windows.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
<<<<<<< HEAD
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
=======
  AppLinksPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AppLinksPluginCApi"));
>>>>>>> 9e5acd308a34305deef445040d0b5a4199af460a
  GeolocatorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("GeolocatorWindows"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
