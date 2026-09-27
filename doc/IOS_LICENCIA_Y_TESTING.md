# iOS — Cómo se prueba, cuándo se paga y cómo se instala

Para releer cada tanto. No es el plan de la app: solo este tema.

Fecha: 24 de septiembre de 2026.

---

## La idea en una frase

**Desarrollás el código en Windows. Lo probás en Android. Para iPhone hace falta una Mac que compile. La licencia de 99 USD no es para vos al principio: es para que la empresa se la mande a sus testers por TestFlight.**

---

## Tres palabras que no hay que mezclar

| Palabra | Qué significa acá |
|---|---|
| **Desarrollar** | Escribir el código Flutter. Se hace en Windows. Ese código sirve para Android e iOS. |
| **Compilar** | Convertir el código en la app que el teléfono entiende. En Windows sale Android (APK). En una Mac sale iPhone (IPA). |
| **Licencia Apple** | Membresía de la **empresa** (99 USD/año). No es un código que se pega en el programa. Es la cuenta que **firma** la app y permite TestFlight / App Store. |

---

## Qué se puede hacer en cada momento

### Ahora (Windows, sin pagar Apple)

- Escribir toda la app.
- Probarla en un Android o en el emulador.
- Validar login, unidades, acciones, video contra MAIC Server.

**No se puede:** abrir un iPhone simulador, ni instalar la app en un iPhone. Windows no tiene Xcode.

### Si aparece una Mac (todavía sin pagar los 99)

- Compilar para iOS.
- Probar en el **simulador** de iPhone (en la Mac).
- Instalar en **un iPhone enchufado a esa Mac** (Apple ID gratis).

Sirve para que **vos** la veas en iOS. El perfil del teléfono **vence ~7 días** y hay que volver a instalar. No sirve para mandársela a los testers de ellos por mail.

### Si la empresa paga la licencia (Organization)

- Te agregan a su equipo. Vos no pagás.
- Se sube el compilado a **TestFlight**.
- **Sus testers la instalan en SUS iPhones** (app TestFlight). Sin Mac, sin cable.
- Después se puede publicar en el App Store (o distribución privada).

---

## El flujo correcto (de punta a punta)

```
1. Vos desarrollás en Windows
        ↓
2. Probás en Android
        ↓
3. Cuando toque iOS: una Mac (tuya, de ellos, o un build en la nube) COMPILA
        ↓
4a. Sin licencia: instalás en UN iPhone con cable, para vos
4b. Con licencia de la empresa: se sube a TestFlight
        ↓
5. Los testers abren TestFlight en el iPhone y prueban AHÍ
```

**La Mac no es donde prueban los testers.**  
La Mac **fabrica** la app. Los testers la usan en el **iPhone**.

---

## Instalar y probar en un iPhone — ¿hace falta licencia?

| Situación | ¿Licencia paga? |
|---|---|
| Yo tengo Mac + mi iPhone, lo enchufó y la instalo | **No** |
| Yo tengo solo iPhone, sin Mac, y estoy en Windows | **No se puede** (falta la Mac, no la licencia) |
| Ellos quieren probarla en varios iPhone, cada uno en su casa | **Sí** (TestFlight) |
| Publicar en el App Store | **Sí** |

No es como Android: no se manda el archivo por WhatsApp y el otro lo instala. iOS exige o el cable en la Mac, o TestFlight.

---

## Qué es “la licencia” (y qué no es)

Se paga en [developer.apple.com/programs](https://developer.apple.com/programs/).

**No es** un código / PIN / serial adentro del proyecto Flutter.

**Sí es** una membresía anual. Apple abre una cuenta de empresa y con eso:

1. Genera **certificados** (un sello digital: “esta app la publica *Empresa X*”).
2. Xcode o el CI usan ese sello al **compilar**.
3. App Store Connect recibe el `.ipa`.
4. TestFlight o el Store se la entregan al iPhone.

El código de la app casi no cambia. Lo que cambia es **quién tiene permiso de firmarla y distribuirla**.

---

## Pasos cuando la empresa se hace cargo

1. Se anotan como **Organization** (no Individual).
2. Mandan razón social, **D-U-N-S**, mail corporativo. Tarda **1–2 semanas**.
3. Pagan **USD 99 al año**.
4. Te invitan como developer. Ellos son dueños de la app.
5. Se crea el App ID / bundle (`com.empresa.maic.mobile`).
6. Se compila en Mac o CI y se sube a TestFlight.
7. Testers instalan **TestFlight** → aceptan → usan la app en el iPhone.
8. Cuando esté lista: revisión de Apple y publicación.

**No publicar con tu Apple ID personal.** En el Store figuraría tu nombre, no el de ellos. Transferir después es un trámite.

Hay otro programa (Enterprise, 299 USD) para distribución interna por MDM. Al inicio **no hace falta**.

---

## Cómo decírselo a ellos

> Desarrollamos y validamos en Android, que es el mismo código.  
> Para verla en un iPhone hace falta un Mac que compile; eso no es la licencia.  
> Los 99 USD anuales a nombre de la empresa sirven para TestFlight y para que sus testers la instalen en sus teléfonos.  
> La app tiene que quedar a nombre de ustedes, no de una cuenta personal.

---

## Android, para no confundir

| | Android | iOS |
|---|---|---|
| Desarrollar en Windows | Sí | El código sí; el binario no |
| Probar en el teléfono ahora | Sí | No, sin Mac |
| ¿Se paga para desarrollar? | No | No |
| ¿Se paga para publicar? | Play Console, **USD 25 una vez**, a nombre de la empresa | Developer Program, **USD 99/año**, a nombre de la empresa |
| ¿Se manda el archivo y se instala? | APK se puede (con cuidado) | No. Cable o TestFlight |

---

## Cómo compilar si tenés una Mac

El proyecto ya tiene carpeta `ios/`. En la Mac solo se **compila** el mismo código.

### 1. Dejar la Mac lista (una vez)

1. Instalá **Xcode** desde el App Store (pesa varios GB; tarda).
2. Abrí Xcode una vez, aceptá la licencia, instalá *additional components*.
3. En Terminal:

```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
```

4. Instalá **Flutter** (si no está) y **CocoaPods**:

```
brew install cocoapods
flutter doctor
```

`flutter doctor` tiene que mostrar Xcode en verde. El iOS toolchain no puede quedar en rojo.

### 2. Copiar el proyecto

Pasá la carpeta `app-mobile` (pendrive, git, iCloud). En la Mac:

```
cd /ruta/a/app-mobile
flutter pub get
cd ios
pod install
cd ..
```

### 3. Probar en el simulador (sin iPhone, sin pagar)

```
open -a Simulator
flutter devices
flutter run
```

Elegí un iPhone de la lista (simulator). Ahí ves la app: demo, login, cámaras. El video en simulador a veces anda peor que en un iPhone real; para el live conviene el teléfono.

### 4. Instalarla en TU iPhone (sin los 99 USD)

1. Cable. En el iPhone: confiá en la computadora.
2. Apple ID (el tuyo alcanza).
3. Abrí una vez el proyecto nativo:

```
open ios/Runner.xcworkspace
```

Usá el `.xcworkspace`, **no** el `.xcodeproj`.

4. En Xcode: Runner → *Signing & Capabilities* → tildá *Automatically manage signing* → Team = tu Apple ID (Add Account si hace falta).
5. Bundle ID: `com.maic.maic_mobile`. Si Xcode dice que está tomado, cambiá a algo tuyo solo para prueba (`com.tuapellido.maic.mobile`).
6. Arriba, dispositivo = tu iPhone.
7. Desde la Terminal del proyecto:

```
flutter run
```

O el botón Play de Xcode.

La primera vez el iPhone pide **Confiar en el desarrollador**: Ajustes → General → VPN y gestión de dispositivos.

Con cuenta **gratis** el perfil **vence ~7 días**. Hay que volver a enchufar y `flutter run`.

### 5. Armar el archivo para TestFlight (con la licencia de la empresa)

Cuando te hayan agregado al equipo Organization:

1. En Xcode, Team = **la empresa**, no tu cuenta personal.
2. Bundle ID el que ellos registraron.
3. En la Mac, en la carpeta del proyecto:

```
flutter build ipa
```

Sale un `.ipa` en `build/ios/ipa/`.

4. [App Store Connect](https://appstoreconnect.apple.com) → la app MAIC → TestFlight.
5. Subís el `.ipa` con **Transporter** (app de Apple) o:

```
xcrun altool --upload-app ...
```

(Xcode → Window → Organizer → Distribute también sirve.)

6. Apple procesa el build (minutos / un rato).
7. Invitás testers. Ellos instalan **TestFlight** en el **iPhone**.

### Si algo falla

| Error | Qué mirar |
|---|---|
| `pod install` falla | `cd ios && pod install --repo-update` |
| No aparece el iPhone | Cable, desbloquear, “Confiar”, `flutter devices` |
| Signing / team | Xcode → Signing; Team correcto |
| VLC / permisos | Ya está `NSAllowsArbitraryLoadsInMedia` en `Info.plist` |
| Simulador sin video | Probar en iPhone físico |

No hace falta reescribir el código Dart para iOS. Es el mismo `lib/`.

---

## Mini chequeo (para cuando lo releas)

- [ ] ¿Estoy desarrollando? → Windows + Android. No hace falta Apple.
- [ ] ¿Quiero verla yo en iOS? → Necesito una **Mac**. No necesito pagar.
- [ ] ¿Quiero que la prueben ellos en sus iPhone? → Mac (o CI) **+** licencia de la **empresa** + TestFlight.
- [ ] ¿La licencia es un código en el programa? → **No.** Es la cuenta que firma y publica.
- [ ] ¿Los testers prueban en la Mac? → **No.** Prueban en el iPhone.

Documento hermano: `PLAN_MAIC_MOBILE.md` (producto y stack). Este archivo es solo iOS / licencia / testing.
