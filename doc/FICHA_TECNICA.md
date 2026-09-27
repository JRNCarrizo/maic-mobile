# MAIC.Mobile — Ficha técnica

Fecha: 27 de septiembre de 2026.  
Producto: cliente móvil de operador. Android + iOS.  
Contrato: MAIC Server DemoGold 3.16.3 / MAIC.Contracts 3.16.0 / VideoRecorder 3.18.49.

---

## Identificación

| Campo | Valor |
|---|---|
| Nombre | MAIC.Mobile |
| Paquete | `maic_mobile` |
| Application ID | `com.maic.maic_mobile` |
| Versión actual | 0.1.0+1 |
| Plataformas objetivo | Android e iOS |
| Código | Un solo proyecto Flutter |

---

## Stack principal

| Capa | Tecnología | Para qué |
|---|---|---|
| Framework | **Flutter 3** (stable 3.47.x) | UI y un codebase para ambos OS |
| Lenguaje | **Dart 3.13** | Toda la lógica de la app |
| Video | **libVLC** vía `flutter_vlc_player_16kb`; MP4 demo con `video_player` | MPEG-TS live H.264/H.265; clip demo |
| HTTP / JSON | **Dio** | API MAIC, timeouts, header `X-MAIC-Session` |
| Estado | **Riverpod** | Sesión, unidades, live, alarmas |
| Navegación | **go_router** | Login, cámaras, live, grilla |
| Preferencias | **shared_preferences** | Endpoint del server, modo demo/real, última vista en demo |
| IDs | **uuid** | `correlationId`, `machineName` |
| Realtime | **signalr_netcore** | Hub `/hubs/platform`, evento `SessionClosed` |
| Tests | **flutter_test** + **flutter_lints** | Unit / widget y análisis estático |

La **sesión** (`sessionId`) vive **solo en memoria**. No se persiste la contraseña.

---

## Qué no usamos (y por qué)

| Tecnología | Motivo |
|---|---|
| Capacitor / Ionic / WebView | El live es HTTP MPEG-TS + H.265. En iOS (WKWebView) no es fiable. |
| React Native | Se podía con VLC; Flutter encaja mejor para grilla y un repo de cero. |
| Kotlin + Swift (dos apps) | El contrato se implementaría dos veces. |
| AVPlayer (iOS) como player único | No come MPEG-TS live. Por eso VLC en los dos teléfonos. |
| SDKs Dahua / ONVIF / RISCO | Quedan en MAIC Server. La app no habla con las cámaras. |

---

## Arquitectura

Capas + features. Las pantallas no llaman a Dio ni a VLC.

```
UI (features)
    → application (Riverpod)
        → domain (entidades + puertos)
            ↑
data (Dio, SharedPreferences, SignalR, VLC)
```

Carpetas: `lib/app`, `lib/core`, `lib/domain`, `lib/data`, `lib/features`, `lib/ui`.

---

## Integración con MAIC Server

| Transporte | Uso |
|---|---|
| HTTPS + JSON (puerto 5443 por defecto) | Login, unidades, acciones, eventos, layouts |
| HTTP MPEG-TS (`relay.streamUrl`) | Video `target=mobile` |
| WSS / SignalR (`/hubs/platform`) | `SessionClosed` |

Protocolo de acciones: un solo `POST /api/platform/unit-actions/execute`.  
Éxito de una acción = `result == true` **y** `data.success == true`.

---

## Nativo (mínimo)

| OS | Qué se configuró |
|---|---|
| Android | Permiso Internet; Network Security Config (HTTP del relay) |
| iOS | `NSAllowsArbitraryLoadsInMedia` (HTTP solo para media/relay) |

Compilar iOS requiere **macOS + Xcode**. Publicar: Apple Developer Organization (empresa) y Play Console.

---

## Dependencias (pubspec)

```
dio                  ^5.9.0
flutter_riverpod     ^2.6.1
go_router            ^16.2.4
shared_preferences   ^2.5.3
uuid                 ^4.5.1
flutter_vlc_player_16kb ^7.4.7
video_player         ^2.10.0
signalr_netcore      ^1.4.4
flutter_lints        ^6.0.0
```

---

## Cómo decírselo a alguien

> App Flutter (Dart) para Android e iOS. Habla HTTPS/JSON con MAIC Server. El video lo reproduce VLC (libVLC), no un navegador. Estado con Riverpod, HTTP con Dio, realtime con SignalR. Sin SDKs de cámaras.

Documentos hermanos: `ESTADO_DEL_PROYECTO.md` (hecho vs falta), `PLAN_MAIC_MOBILE.md` (plan), `IOS_LICENCIA_Y_TESTING.md` (Apple).
