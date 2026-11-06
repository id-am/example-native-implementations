# call_state

`call_state` es un plugin Flutter con implementaciones nativas para Android e iOS. Flutter lo integra a partir de los metadatos declarados en su `pubspec.yaml`; no es necesario registrar la clase manualmente en la aplicación.

## Cómo se registra en Android

1. La aplicación declara el plugin como dependencia local en [`apps/call_state_app/pubspec.yaml`](../../apps/call_state_app/pubspec.yaml):

   ```yaml
   dependencies:
     call_state:
       path: ../../packages/call_state
   ```

2. Flutter lee la sección `flutter.plugin.platforms.android` de este paquete, en [`pubspec.yaml`](./pubspec.yaml):

   ```yaml
   android:
     package: com.example.call_state
     pluginClass: CallStatePlugin
   ```

   `package` identifica el paquete Kotlin/Java de la implementación y `pluginClass` indica el nombre de la clase que Flutter debe cargar. Juntos identifican `com.example.call_state.CallStatePlugin`.

3. Al resolver las dependencias y preparar la compilación Android, Flutter genera `GeneratedPluginRegistrant.java` con las clases nativas de los plugins Android encontrados. En el proyecto de ejemplo, ese archivo contiene una llamada equivalente a:

   ```java
   flutterEngine.getPlugins().add(new com.example.call_state.CallStatePlugin());
   ```

   El registrant también incluye otros plugins presentes en las dependencias, como `permission_handler_android`.

4. Una vez añadido al engine, Flutter llama a `onAttachedToEngine` de `CallStatePlugin`. Allí se configuran los canales `call_state/methods` y `call_state/events` que usa Dart.

## iOS

La sección `flutter.plugin.platforms.ios` del mismo `pubspec.yaml` declara la clase Swift del plugin. Flutter usa esa metadata junto con `ios/call_state.podspec` para integrar la implementación iOS mediante CocoaPods.
