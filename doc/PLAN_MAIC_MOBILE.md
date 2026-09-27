# MAIC.Mobile — Plan de desarrollo

Documento de continuidad. Si se pierde el chat, este archivo + el contrato alcanzan para retomar.

Resumen hecho vs falta: **`doc/ESTADO_DEL_PROYECTO.md`**.  
Ficha de tecnologías: **`doc/FICHA_TECNICA.md`**.

| Campo | Valor |
|---|---|
| Fecha del plan | 24 de septiembre de 2026 |
| Contrato | `doc/MAIC_Mobile_Integration_Contract_v1.1.docx` |
| Versión contractual | 1.1 — DemoGold 3.16.3 / MAIC.Contracts 3.16.0 / VideoRecorder 3.18.49 MobileChunkedHttp |
| Estado del repo | Vacío salvo documentación. Todavía no hay código. |
| Decisión de stack | **Flutter + libVLC**. No Capacitor. |
| Arquitectura | Capas + features. UI ↛ Dio/VLC. Dominio sin Flutter. |

---

## 1. Qué es este producto

App **Android + iOS** para operadores. Se conecta **solo** a **MAIC Server** (plataforma intermedia). El server habla con las VMS/cámaras/NVR (Dahua, ONVIF, RISCO, etc.) y le entrega a la app **siempre el mismo formato**.

La app **nunca**:

- se conecta a IP/puerto de una cámara o NVR
- usa RTSP, ONVIF ni SDK de fabricante
- guarda credenciales de dispositivos

El contrato lo resume así: *todo lo de fabricante queda en Server; todo lo de presentación y reproducción queda en Mobile*.

---

## 2. Decisión de tecnología (no reabrir sin motivo fuerte)

Se evaluó Capacitor porque el equipo venía de esa pregunta. **Se descartó como stack principal.**

| Opción | Veredicto |
|---|---|
| Capacitor / WebView | Sirve para login y listas. **Falla el video**: MPEG-TS live + H.265 no es fiable en WKWebView. |
| React Native + VLC | Viable. Más puente y más fricción para grilla de lives. |
| Kotlin + Swift nativo | Máxima calidad, peor costo: el contrato se implementaría dos veces. |
| .NET MAUI | Tienta por el server .NET. Para un equipo independiente, Flutter es más sólido en UI/stores. |
| **Flutter + VLC** | **Elegido.** Un código, UI nativa, video nativo embebido. |

### Stack cerrado

| Capa | Tecnología |
|---|---|
| App | Flutter 3 (Dart), un codebase → Android + iOS |
| Video | libVLC (`flutter_vlc_player` o plugin propio). Mismo motor en ambos OS. |
| HTTP | Dio + interceptors (`X-MAIC-Session`, timeouts, correlationId) |
| Estado | Riverpod |
| Modelos | Freezed + json_serializable |
| Secretos / preferencias | `flutter_secure_storage` para lo sensible; endpoint en preferencias normales |
| Sesión | **Solo en memoria.** No persistir password ni `sessionId`. |
| Rutas | go_router |
| Realtime | `signalr_netcore` (opcional; hoy solo `SessionClosed` está confirmado) |
| Android extra | Network Security Config: cleartext **solo** para hosts de relay |
| iOS extra | ATS puntual: HTTP solo para `relay.streamUrl`, nunca para la API |
| CI | Codemagic o GitHub Actions (AAB + IPA) |

**Por qué VLC y no AVPlayer/ExoPlayer solo:** el video llega como **HTTP MPEG-TS live** (no HLS). ExoPlayer lo banca en Android. AVPlayer en iOS no. VLC come MPEG-TS + H.264 + H.265 en los dos.

---

## 3. Contrato que la app debe respetar

Fuente de verdad: el `.docx` de esta carpeta. Resumen operativo:

### Conexión

- El usuario ingresa host o URL. Normalizar a `https://host:puerto/`.
- Puerto por defecto: **5443**.
- Tirar path/query/fragment. Rechazar `https://usuario:clave@host`.
- Antes del login: `GET /api/platform/system/health` **sin** credenciales.
- TLS de la API se valida. No desactivar SSL “porque es lab”.
- Pinning: opcional, política de despliegue, no requisito del server.

### Sesión

- `POST /api/platform/auth/login` con `domain=""`, `useIntegratedAuthentication=false`.
- Validar `result == true` **y** `data.success == true` **y** `session != null`.
- Header: `X-MAIC-Session: <sessionId>` solo hacia MAIC Server.
- Heartbeat `POST /api/session/heartbeat` ~10 s. Ventana server ~3 min.
- No invalidar sesión por un corte de red transitorio.
- Logout: `POST /api/session/release` best-effort y borrar sesión local.
- SignalR `/hubs/platform?sessionId=...`: si llega `SessionClosed`, volver a login.

### Unidades y acciones

- Unidades: `GET /api/platform/modules/MAIC.Module.Viewer/units`.
- Canales: acción `videorecorder.refreshDeviceInfo`. Usar `inventory.channel.{N}.requestChannel`, no asumir `N+1`.
- Todas las operaciones: `POST /api/platform/unit-actions/execute`.
- Cada llamada lleva `correlationId` único.
- **Doble éxito:** `ApiResponse.result == true` **y** `data.success == true`.

### Video (lo crítico)

- Abrir con `videorecorder.stream.open`, `target: "mobile"`.
- `subtype`: `0` Main, `1` Substream.
- Reproducir **exactamente** `relay.streamUrl`. No reconstruirla. No pasarla a HTTPS.
- Contenedor: MPEG-TS. Codec: H.264 **o** H.265 (HEVC es caso normal).
- Live no seekable. Si corta el socket → ticket nuevo si la URL ya no sirve.
- Cerrar: `videorecorder.stream.close` con `relayLeaseId`, best-effort.
- `openMany` admite éxito parcial.
- No persistir ni loguear lease / URL completa.

### Eventos

- REST: `/api/platform/events` y `/api/platform/alarms`.
- Ack: `POST /api/platform/alarms/{alarmId}/ack`.
- Realtime **no** reemplaza esas consultas en DemoGold 3.16.3.

### Seguridad / logs

**No loguear ni persistir:** password, `sessionId` completo, `relayLeaseId`, `streamUrl` completa, `snapshot.base64`.

**Sí loguear:** `correlationId`, `unitId`, `actionKey`, `code`, `errorKind`, `durationMs`.

---

## 4. Arquitectura sólida y escalable

No es una app “toda la lógica en las pantallas”. Se arma en **capas + features**.
Así se puede sumar un módulo nuevo de MAIC Server (otra acción, otro tipo de unidad, otro player) sin reescribir login ni el cliente HTTP.

### 4.1 Principio

El server ya es genérico: un solo `unit-actions/execute`, capabilities, JSON que tolera campos nuevos.
La app tiene que ser igual de genérica. **Nada de `if (brand == Dahua)`.**

Tres reglas que no se rompen:

1. **La UI no habla con Dio ni con VLC.** Llama a un caso de uso.
2. **El dominio no conoce Flutter, Dio ni libVLC.** Solo tipos y puertos (interfaces).
3. **Un feature no importa la UI de otro.** Si necesita algo, pasa por dominio o por `core`.

Flujo de dependencias (siempre hacia adentro):

```
UI (pantallas)
    → application (casos de uso / Riverpod)
        → domain (entidades + puertos)
            ↑
data / adapters  (Dio, SecureStorage, SignalR, VLC)
```

`data` implementa los puertos de `domain`. La UI nunca salta directo a `data`.

### 4.2 Estructura de carpetas

```
lib/
  app/                      arranque, router, inyección de dependencias
    bootstrap.dart
    router.dart
    providers.dart

  core/                     piezas transversales, sin pantallas
    endpoint/               normalizar URL, puerto 5443, rechazar user:pass
    network/                Dio, interceptors, ApiResponse<T>
    session/                header X-MAIC-Session (sin persistir)
    errors/                 Timeout, TransportError, mapeo de códigos server
    logging/                logger sanitizado
    ids/                    correlationId, machineName
    constants/              moduleId, actionKey (un solo lugar)

  domain/                   contrato de negocio, testeable sin UI
    auth/
    units/
    actions/                ExecuteRequest / ExecuteResult (doble éxito)
    video/                  VideoTicket  (URL + lease, no player)
    events/
    layouts/
    ports/                  interfaces: ApiPort, SessionPort, PlayerPort...

  data/                     implementaciones concretas, reemplazables
    api/                    DioApiClient
    auth/                   login / heartbeat / release
    units/
    actions/                POST unit-actions/execute
    video/                  VideoTicketService  ← pide ticket, no reproduce
    player/                 VlcPlayerAdapter    ← único lugar que importa VLC
    events/
    realtime/               SignalR (opcional)
    storage/                secure storage + preferencias + module-layouts

  features/                 una carpeta por capacidad de producto
    connection/             alta de server, health, TLS
    auth/                   login / sesión / logout
    units/                  catálogo, grupos, inventario de canales
    live/                   1 cámara o grilla; usa ticket + player
    snapshot/
    actuators/              relé, strobe, sirena… solo si Server autoriza
    events/                 eventos + alarmas + ack
    layouts/                vistas guardadas

  ui/                       tema, widgets chicos reutilizables (botón, chip)
```

Cada `features/<nombre>/` por dentro:

```
features/live/
  application/    providers / notifiers (Riverpod)
  presentation/   pantallas y widgets de ESA feature
```

No se mete Dio adentro de `presentation`. No se mete un `VideoPlayer` adentro de `data/video`.

### 4.3 Por qué escala (casos reales)

| El server / el negocio suma… | Qué se toca | Qué no se toca |
|---|---|---|
| Una acción nueva (`pulseRelay`, analítica, etc.) | Constante `actionKey` + parser opcional en `data/actions` + UI en su feature | Cliente HTTP, login, player |
| Un módulo nuevo (no VideoRecorder) | Feature nueva + mismos `UnitAction` / `ApiResponse` | `core/network`, auth, VLC |
| Otro reproductor (ExoPlayer, media_kit) | Solo `data/player` (otro adapter del `PlayerPort`) | Tickets, contratos, pantallas |
| Eventos realtime cuando Server los publique | `data/realtime` + el feature `events` | Auth, units, video |
| Más pantallas / otra marca visual | `features/*/presentation` + `ui/` | Dominio y red |
| Otro OS (el mismo código) | Nada de negocio; solo config nativa Android/iOS | Dart |

Eso es escalar: **agregar carpetas, no inflar un God-class**.

### 4.4 Contratos internos (puertos)

Quedan fijos desde el día 1. Las implementaciones se pueden cambiar.

```
EndpointPort        normalizar + persistir host
HealthPort          GET /system/health
AuthPort            login / heartbeat / release
UnitCatalogPort     listar units Viewer + refreshDeviceInfo
UnitActionPort      execute (doble éxito + correlationId + retry)
VideoTicketPort     open / openMany / close
PlayerPort          play(streamUrl) / stop / attach  ← sin saber de MAIC
EventPort           events / alarms / ack
RealtimePort        connect + SessionClosed
LayoutPort          list / save / delete
```

Servicios del contrato §15 mapeados:

| Contrato MAIC | Dónde vive |
|---|---|
| Endpoint/Trust Service | `core/endpoint` + `data` |
| ApiClient | `core/network` + `data/api` |
| Auth/Session Service | `domain/auth` + `data/auth` |
| UnitCatalog Service | `domain/units` + `data/units` |
| UnitAction Service | `domain/actions` + `data/actions` |
| VideoTicket Service | `domain/video` + `data/video` |
| VideoPlayer Adapter | `domain/ports/PlayerPort` + `data/player` |
| Realtime Service | `data/realtime` |
| Event Service | `domain/events` + `data/events` |
| ServerStorage Service | `data/storage` |

### 4.5 Estado (Riverpod) para que no se pudra

- **SessionController:** un solo dueño de la sesión. Si muere la sesión, el router manda a login.
- **Cada feature tiene su notifier.** Live no escribe adentro de Units.
- Tickets de video viven en el feature `live`, no en un singleton eterno.
- Al salir de una pantalla de live: `close` best-effort + dispose del player.

### 4.6 Tests (la estructura los hace baratos)

| Tipo | Qué cubre | Sin qué |
|---|---|---|
| Unit | normalizar URL, doble éxito, parseo de `inventory.channel.*.requestChannel`, backoff | red, UI, VLC |
| Unit | logger no filtra secretos | — |
| Widget | login, lista vacía, error `userMessage` | server real |
| Integración | health → login → units (mock Dio) | dispositivo |

Si hay que pegarle a un Server real, es un test manual / checklist, no la base de la arquitectura.

---


## 5. Orden de implementación

No pintar pantallas de más hasta que el live funcione.

| # | Entrega | Hecho |
|---|---|---|
| 0 | Repo Flutter + carpetas §4 (core / domain / data / features) + checklist | Sí |
| 1 | Endpoint + health + login + heartbeat + logout | Sí (mock + remoto) |
| 2 | Lista de unidades Viewer + inventario de canales | Sí (mock + remoto) |
| 3 | Snapshot y acciones (relé, etc.) | Sí (snapshot + pulso relé; mock + remoto) |
| 4 | **Un** live MPEG-TS (substream) con VLC | Sí (demo=clip; real=streamUrl) |
| 5 | Main Stream HEVC + fallback a substream | Sí (Sub/Main; fallback si falla el decode) |
| 6 | `openMany` (2–4 cámaras) | Sí (grilla; éxito parcial) |
| 7 | Eventos / alarmas REST + ack | Sí (pestaña + mock + remoto) |
| 8 | SignalR `SessionClosed` | Sí (real + simular en demo) |
| 9 | Layouts / última vista (`module-layouts`) | Sí |

Sin el paso 4 estable, no seguir con UX de más.

---

## 6. Checklist de conformidad (copiado del contrato)

Marcar al implementar:

- [ ] Endpoint solo HTTPS; puerto 5443 si no viene
- [ ] TLS validado; probe de health sin credenciales
- [ ] Password no se persiste
- [ ] Login valida `result` + `data.success` + `session`
- [ ] `X-MAIC-Session` solo a MAIC autenticado
- [ ] Heartbeat + cierre/expiración de sesión
- [ ] Units desde Viewer
- [ ] Canales con `requestChannel`
- [ ] Acciones vía `unit-actions/execute` + `correlationId`
- [ ] Doble nivel de éxito
- [ ] Video con `target=mobile`
- [ ] Se consume `relay.streamUrl` sin reconstruirla
- [ ] Player acepta MPEG-TS live no seekable
- [ ] H.264 y H.265, o fallback explícito
- [ ] Cero acceso directo a cámara/NVR/RTSP/SDK
- [ ] `openMany` con resultados parciales
- [ ] Leases se cierran best-effort y no se persisten/loguean
- [ ] Corte de video → ticket nuevo cuando corresponda
- [ ] Realtime, si existe, maneja `SessionClosed`
- [ ] Eventos/alarmas por REST
- [ ] Logs sanitizados
- [ ] Extensiones futuras vendor-neutral detrás de MAIC Server

---

## 7. Cómo retomar en 10 minutos

1. Abrir este archivo y el contrato `.docx`.
2. Stack ya decidido: **Flutter + VLC**. No volver a Capacitor salvo pedido explícito del cliente.
3. Si el repo sigue sin `pubspec.yaml`, el siguiente paso es **crear el proyecto Flutter** y el esqueleto de la §4 (capas + features, sin pantallas de más).
4. Implementar en el orden de la §5, empezando por auth.
5. Probar contra un MAIC Server real (health → login → units → `stream.open` target mobile).
6. El video se prueba con **substream primero**; HEVC después.

Servidor de referencia (del contrato):

- API: `https://<host>:5443/`
- Relay típico (no hardcodear): `http://<host>:37888` o `:37889`
- Siempre ganar `relay.streamUrl` sobre cualquier puerto por defecto

---

## 8. Decisiones que ya no hay que rediscutir

1. Un solo codebase Flutter para Android e iOS.  
2. VLC como reproductor; no WebView, no `mpegts.js` como camino principal.  
3. VideoTicket y Player son módulos distintos (`PlayerPort` intercambiable).  
4. H.265 no es “extra”: el Main Stream puede venir así.  
5. Capacitor queda descartado para este producto.  
6. Arquitectura por capas + features: la UI no llama a Dio/VLC; el dominio no importa Flutter.  
7. Acciones nuevas = `actionKey` + feature, nunca un cliente HTTP nuevo ni `if` por marca.  
8. No hay código todavía; este plan es el punto de partida.

---

## 9. Cómo explicar la elección de tecnologías

Usar esto si el cliente, un socio o otro dev pregunta “¿por qué Flutter y VLC, y no Capacitor / nativo / React Native?”.

### Pitch corto (30 segundos)

> Elegimos Flutter + VLC porque la app tiene que vivir en Android e iOS con el **mismo contrato**, y el punto difícil no es la UI: es reproducir **video live MPEG-TS con H.264 y H.265** que entrega MAIC Server. Flutter nos da un solo código para toda la app. VLC es el reproductor que realmente come ese formato en los dos teléfonos. Capacitor serviría para login y listas, pero el WebView no banca ese video de forma fiable. Dos apps nativas darían el mismo resultado a casi el doble de costo y con el riesgo de implementar el protocolo dos veces.

### Versión reunión (2 minutos)

1. **El server ya resolvió lo difícil de los fabricantes.** La app no tiene que integrar Dahua, ONVIF ni RISCO. Solo habla HTTPS/JSON con MAIC y reproduce una URL estándar. Entonces no hace falta un SDK nativo por marca.
2. **Lo que sí es difícil es el video.** No es YouTube ni HLS. Es un live MPEG-TS, a veces H.265, a veces varias cámaras. Eso no lo resuelve un `<video>` de navegador.
3. **Flutter** = una base para login, sesión, unidades, acciones, alarmas y pantallas, igual en Android y iOS. Menos divergencia, más rápido de mantener, y la arquitectura queda alineada al contrato (un `execute`, capabilities, sin `if` por marca).
4. **VLC** = el motor de video nativo embebido. En Android ExoPlayer también podría; en iOS AVPlayer no come MPEG-TS live. VLC lo hace en los dos, con el mismo comportamiento.
5. **Por qué no Capacitor:** el 80% de las pantallas sí, el 20% que es el producto (el live) no. Si el video falla, la app no sirve.
6. **Por qué no Kotlin + Swift:** máxima calidad, peor negocio. El contrato es grande (sesión, doble éxito, leases, inventario). Dos implementaciones = dos lugares para el mismo bug.
7. **Por qué no React Native:** se puede con VLC, pero Flutter encaja mejor para grilla de cámaras y para un equipo que arranca de cero en este repo.

### Respuestas a objeciones

| Si dicen… | Responder… |
|---|---|
| “Capacitor es más rápido / ya sabemos web” | Rápido para formularios. Lento o imposible para MPEG-TS + HEVC en iOS. El riesgo está en el live, no en el login. |
| “Hagamos nativo que es más profesional” | El video **sí** es nativo (VLC). La UI y el contrato van en Flutter para no duplicar el protocolo. Profesional es cumplir el contrato una vez, bien. |
| “¿Y si mañana el server manda HLS?” | El player está detrás de un puerto. Se cambia el adapter, no la app. Hoy el contrato dice MPEG-TS y hay que cumplirlo. |
| “Flutter no es de Google / se muere” | Está en producción en bancos y apps grandes. El criterio acá no es moda: es Android+iOS + video nativo + un contrato único. |
| “¿Por qué no MAUI si el server es .NET?” | Los DTOs tientan. Para un equipo mobile independiente, Flutter es más sólido en UI, stores y reproductor. Si más adelante nos dan `MAIC.Contracts` para compartir con el cliente de escritorio, se reevalúa. |

### Una frase para dejar asentado

> *Elegimos la tecnología que mejor cumple el contrato de MAIC, no la que más se parece a una web. Un código, dos sistemas, video nativo.*

---

## 10. iOS: licencia, Mac y qué puede esperar la empresa

Guía para releer (paso a paso, en criollo): **`doc/IOS_LICENCIA_Y_TESTING.md`**.

Pregunta frecuente: *“¿Necesito licencia de Apple ahora? ¿O lo paga la empresa después?”*

**Respuesta corta:** se puede **desarrollar** casi toda la app ahora en Windows, sin pagar Apple. Se puede **probar** en Android. **Probar en iPhone no lo bloquea la licencia: lo bloquea no tener un Mac.** La membresía de USD 99 hace falta para TestFlight, testers externos y publicar, no para el primer compile en un simulador.

### 10.1 Tres cosas distintas (no mezclar)

| Qué | Para qué | ¿Hace falta ahora? |
|---|---|---|
| Código Flutter (Dart) | Login, unidades, acciones, arquitectura | No. Se escribe en Windows. |
| Android (emulador / celular) | Probar el 90% del contrato | No. Una cuenta Google Play puede esperar. |
| **Mac + Xcode** | Compilar y **probar** iOS (simulador o un iPhone) | Sí, el día que se quiera ver la app en iOS. **Esto no es la licencia de USD 99.** |
| Apple Developer Program (USD 99/año) | TestFlight, varios testers, App Store, certificados estables | Sí, el día que se entregue a la empresa o se publique. |

Detalle importante:

- **Sin Mac:** no se prueba iOS. Ni con licencia paga. Windows no corre Xcode ni el simulador de iPhone.
- **Con Mac y Apple ID gratis:** se puede instalar en un iPhone o usar el simulador. En el teléfono el perfil **vence a los 7 días** y hay que reinstalar. Sirve para vos, no para el cliente.
- **Con Mac + Program pago (la empresa):** TestFlight, testers, firma estable, Store.

Flutter no es “una app iOS” hasta que Xcode la firma. Hasta ahí, es el mismo código.

### 10.2 Qué podés hacer vos hoy (sin licencia)

- Crear el proyecto y toda la arquitectura §4.
- Implementar pasos 1–3 del plan (auth, units, acciones, snapshots).
- Probar contra MAIC Server en **Android**.
- Dejar el player detrás de `PlayerPort`; en Android se valida VLC/MPEG-TS.
- El código de iOS (ATS, permisos, `Info.plist`) se puede ir dejando escrito, pero **no se compila en Windows**.

No hace falta iPhone ni cuenta paga para avanzar el producto.

### 10.3 Qué no se puede hacer en Windows

No existe Xcode en Windows. No se puede:

- generar el `.ipa`
- abrir el simulador de iPhone
- firmar con certificado Apple
- subir a TestFlight

Opciones cuando llegue esa etapa:

1. **La empresa pone un Mac** (un Mac mini M-series alcanza). Es lo más simple.
2. **CI en la nube** (Codemagic / GitHub Actions `macos-14`): el repo se buildea en un Mac remoto. Hace falta igual la cuenta Apple para los certificados.
3. **Mac alquilado** (MacStadium, etc.) si no quieren hardware.

Sin una de esas tres, iOS no se entrega. No es un tema de Flutter: es de Apple.

### 10.4 La licencia: que la pague la empresa

| Tipo | Costo | Quién aparece como vendedor | Cuándo usarla |
|---|---|---|---|
| Individual | USD 99/año | Tu nombre y apellido | Solo si el producto es tuyo. **No para este cliente.** |
| **Organization** | USD 99/año | Razón social de la empresa | **Esta.** Ellos son el dueño de la app. |
| Enterprise | USD 299/año | Distribución interna por MDM | Solo si nunca va a App Store y tienen flota propia. Casi nunca hace falta al inicio. |

La empresa se inscribe en [developer.apple.com/programs](https://developer.apple.com/programs/) como **Organization**. Les van a pedir:

- razón social
- **D-U-N-S** (Dun & Bradstreet; en la mayoría de países es gratis, tarda días)
- alguien con poder para firmar contratos
- mail corporativo y web de la empresa

Tarda **1–2 semanas** (a veces más si el D-U-N-S no está o no coincide la dirección). Por eso: **no bloquear el desarrollo**, pero avisarles que lo inicien **antes** de la fecha de prueba en iPhone.

Después te agregan como **developer** al equipo. Vos no pagás la membresía. Los certificados y TestFlight quedan a nombre de ellos.

### 10.5 No publiques con tu Apple ID personal

Si subís MAIC.Mobile con tu cuenta individual:

- en el Store figura **tu nombre**, no el de la empresa
- transferir después se puede, pero es trámite y dolor de cabeza
- si se corta la relación, ellos no son dueños del listing

Regla: **la app nace bajo la cuenta Organization del cliente** (o de la empresa que vaya a ser el publisher).

### 10.6 Flujo correcto (no confundir Mac con tester)

La Mac **no es donde prueban los testers**. La Mac (o el CI) es donde **se construye** el binario iOS. Los testers instalan la app en **iPhone**, igual que el usuario final.

```
Vos (Windows)
  → desarrollás y validás en Android
      → alguien con Mac o CI compila el .ipa
          → se sube a TestFlight (cuenta Apple de la empresa)
              → testers de ellos lo abren en SUS iPhones
```

No se les “da la app para que la prueben en la Mac”. Un operador de vigilancia tiene que ver el live en el teléfono: red móvil, HEVC, touch, segundo plano. El simulador de Mac es herramienta de desarrollo, no de aceptación.

### 10.7 Cómo se prueba iOS cuando exista la cuenta

1. Ellos pagan el Program y te invitan al equipo.
2. Se configura signing (Xcode / Codemagic con el `.p8` de App Store Connect).
3. Build → **TestFlight**.
4. Testers instalan TestFlight y prueban sin pasar por revisión pública todavía.
5. App Store o distribución privada (Apple Business Manager / unlisted) cuando el producto esté.

Para un sistema de vigilancia suele convenir **TestFlight interno** primero, y después decidir si es Store pública o app custom para clientes.

### 10.8 Cómo decírselo al cliente

> Podemos desarrollar y validar todo el contrato ahora en Android, que es el mismo código de iOS. Probar en un iPhone no depende primero de la licencia: depende de un Mac (de ustedes o un build en la nube). La membresía Apple Developer (99 USD/año a nombre de la empresa) hace falta cuando queramos mandar TestFlight o publicar. No bloquea el arranque. No conviene hacerlo con una cuenta personal mía: la app tiene que quedar a nombre de la empresa.

### 10.9 Google Play (para no olvidarlo)

Android se desarrolla sin pagar. Publicar en Play Console es **USD 25 una vez**, también a nombre de la **organización**. Misma lógica: lo paga la empresa, no se publica como persona física si el producto es de ellos.

---

## 11. Contexto de la conversación original

- Cliente necesita app mobile Android + iOS.  
- Plataforma intermedia (MAIC Server) conecta a las VMS.  
- Ellos normalizan APIs/SDKs; la app consume un formato único.  
- Documentación entregada el 22/09/2026.  
- Se preguntó si hacerlo con Capacitor. Respuesta: no para el video; Flutter + VLC.  
- Se pidió documentar el plan para no perder el hilo.

Cuando se retome: *“seguí el `doc/PLAN_MAIC_MOBILE.md`, paso 0/1”*.
Si preguntan por el stack: sección 9. Si preguntan por iOS/licencia Apple: sección 10.
