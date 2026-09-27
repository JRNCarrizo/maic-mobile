# MAIC.Mobile

Cliente Android + iOS de MAIC. Habla solo con MAIC Server.

Documentación: `doc/PLAN_MAIC_MOBILE.md`, `doc/IOS_LICENCIA_Y_TESTING.md`, contrato en `doc/`.

## Cómo correrla

Hace falta Flutter (`C:\Users\Jorge Carrizo\flutter`). En una terminal nueva:

```
flutter pub get
flutter test
flutter run
```

En casa, sin servidor: en el desplegable elegí **demo@demo** (ya viene usuario y clave `demo`) y tocá **Ingresar**.

## APK

- **Local (probar ya):** `flutter build apk --release`  
  Sale en `build/app/outputs/flutter-apk/app-release.apk`.
- **GitHub (compartir):** Actions → *Android APK* → Run workflow.  
  Un tag `v0.1.0` además crea un [Release](https://github.com/JRNCarrizo/maic-mobile/releases) con la APK.

Hoy el release se firma con la key de debug. Para Play Store hace falta un keystore de la empresa.

## Estado

Pasos 0–9 del plan implementados. En casa: modo demo. Contra MAIC: URL real.
