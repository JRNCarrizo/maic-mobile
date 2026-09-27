# MAIC.Mobile — Qué está hecho y qué falta

Fecha: 27 de septiembre de 2026.

Documento para releer. El plan técnico sigue en `PLAN_MAIC_MOBILE.md`. iOS/licencia en `IOS_LICENCIA_Y_TESTING.md`. El contrato es el `.docx` de esta carpeta.

---

## En una frase

**La app del plan (pasos 0 a 9) ya está escrita.** Se puede recorrer en casa con **modo demo**. Falta probarla contra un MAIC Server real y, para iPhone, una Mac + la licencia Apple de la empresa.

---

## Qué hicimos (pasos 0–9)

| # | Entrega | Estado | Cómo se ve en la app |
|---|---|---|---|
| 0 | Proyecto Flutter + capas (core / domain / data / features) | Hecho | Estructura lista para crecer |
| 1 | Endpoint, health, login, heartbeat, logout | Hecho | Primera pantalla + login |
| 2 | Unidades Viewer + canales (`requestChannel`) | Hecho | Pestaña **Cámaras** |
| 3 | Snapshot + pulso de relé | Hecho | En la ficha: cámara / relé |
| 4 | Un live substream + VLC | Hecho | Play en un canal |
| 5 | Main Stream + fallback a Sub (H.265) | Hecho | Chips **Sub / Main** |
| 6 | Grilla `openMany` (2–4, éxito parcial) | Hecho | **Ver N en vivo** en el NVR |
| 7 | Eventos / alarmas REST + ack | Hecho | Pestaña **Alarmas** |
| 8 | SignalR `SessionClosed` | Hecho | En demo: **Simular SessionClosed** |
| 9 | Última vista (`module-layouts`) | Hecho | **Última vista: …** en Cámaras |

Stack: **Flutter + VLC**. Un código para Android e iOS. La app habla **solo** con MAIC Server.

En casa, sin su plataforma: desplegable **demo@demo** → **Ingresar** (usuario/clave `demo` o cualquiera no vacío).

En demo el live es un **clip de prueba**, no MPEG-TS de una cámara. El resto del flujo (sesión, unidades, foto, relé, alarmas, grilla, cierre de sesión) se puede recorrer igual.

---

## Qué faltaría (no es otro paso de código del plan)

Esto es lo que falta para **cerrarlo con el cliente**, no para “seguir programando el 10”.

### 1. Probar contra MAIC Server de verdad

Pediles un ambiente de test (DemoGold):

- URL (ej. `https://host:5443`)
- usuario operador
- VPN si está en una LAN

Ahí se valida de verdad:

- TLS / certificado
- video MPEG-TS + H.265
- permisos, relés, alarmas reales

Sin eso se puede desarrollar. No se puede firmar que el live del producto anda.

### 2. iOS (compilar e instalar)

- En **Windows** se desarrolla y se prueba Android.
- Para **compilar** iPhone hace falta una **Mac** (o CI en la nube). No es la licencia.
- Para que **vos** la instales en un iPhone enchufado a esa Mac: **no** hace falta pagar.
- Para que **ellos** la prueben en sus iPhone (TestFlight) o la publiquen: la **empresa** paga Apple Developer (**USD 99/año**, Organization). No es un código dentro de la app.

Detalle: `IOS_LICENCIA_Y_TESTING.md`.

### 3. Publicar (cuando el producto esté)

- Google Play: **USD 25 una vez**, a nombre de la empresa.
- App Store: la misma membresía Apple del punto 2.

---

## Cómo seguir laburando ahora

```
flutter run
```

Emulador o celular Android. Modo demo. Recorrer:

1. Login  
2. Cámaras → NVR → live / snapshot / grilla  
3. Alarmas → Ack  
4. Sesión → Simular SessionClosed  

Cuando te den el server: misma app, **Agregar servidor**, guardás el host e **Ingresar** con usuario y clave reales.

---

## Documentos de esta carpeta

| Archivo | Para qué |
|---|---|
| `MAIC_Mobile_Integration_Contract_v1.1.docx` | Contrato con el server |
| `PLAN_MAIC_MOBILE.md` | Plan, stack, arquitectura |
| `IOS_LICENCIA_Y_TESTING.md` | Compilar, probar, licencia Apple |
| `ESTADO_DEL_PROYECTO.md` | Este resumen: hecho vs falta |
| `FICHA_TECNICA.md` | Tecnologías y stack |
| `CHECKLIST_TEST.md` | Qué probar en la app |
