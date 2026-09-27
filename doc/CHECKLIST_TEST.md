# MAIC.Mobile — Qué testear

Lista corta para no olvidarse nada. Tachá al probar.

Hay dos ambientes: **demo** (en casa, sin server) y **MAIC real** (cuando te den URL + usuario).

---

## A. Arranque y conexión

- [ ] La app abre en login (servidor + usuario + contraseña)
- [ ] **Modo demo:** desplegable `demo@demo` → Ingresar entra
- [ ] Host vacío / basura en “Agregar servidor” → mensaje claro, no crashea
- [ ] `https://usuario:clave@host` → se rechaza
- [ ] **Real:** host o IP sin puerto → usa `https` y `5443`
- [ ] **Real:** servidor caído al ingresar → error de red, no se manda la contraseña
- [ ] **Real:** certificado malo → se rechaza (no se apaga TLS)
- [ ] **Probar y guardar** comprueba el host y lo deja en IP guardada

## B. Login y sesión

- [ ] Demo: Ingresar con demo/demo (o vacío, se completa solo) → entra
- [ ] Demo: cualquier usuario/clave no vacíos → entra
- [ ] **Real:** usuario/clave mal → mensaje del server, no entra
- [ ] **Real:** usuario/clave bien → ves el nombre y el rol
- [ ] La contraseña no queda guardada al volver
- [ ] **Cerrar sesión** → volvés al login
- [ ] **Cambiar servidor** → cierra sesión y vuelve a conexión
- [ ] Demo: **Simular SessionClosed** → echa al login
- [ ] **Real:** si cierran la sesión desde Platform → la app vuelve al login
- [ ] Dejarla 1–2 min abierta → sigue adentro (heartbeat)

## C. Cámaras / unidades

- [ ] Lista: NVR, Calle, Taller (demo) o las unidades del server (real)
- [ ] Se ve en línea / sin conexión
- [ ] Buscar filtra por nombre
- [ ] Tirar hacia abajo refresca
- [ ] Abrir una unidad → aparecen canales con el número correcto (no inventar N+1)
- [ ] Cámara sin inventario → canal 1
- [ ] Abrir una unidad y volver → **Última vista** apunta a esa
- [ ] Tocar Última vista → abre la misma unidad

## D. Live (una cámara)

- [ ] Play en un canal → se ve video (demo = clip; real = cámara)
- [ ] Arranca en **Sub**
- [ ] Pasar a **Main** y volver a **Sub**
- [ ] **Real:** Main H.265 que el teléfono no banca → baja a Sub y avisa
- [ ] Atrás / salir → se corta el live (no sigue sonando atrás)
- [ ] Corte de red o cámara caída → mensaje y **Reintentar**
- [ ] **Real:** se ve la URL que mandó el server (no reconstruida a mano)

## E. Grilla

- [ ] En NVR (2+ canales) está **Ver N en vivo**
- [ ] Se ven varias celdas
- [ ] Si una falla, las otras siguen
- [ ] Salir cierra todos los lives

## F. Snapshot y relé

- [ ] Ícono de cámara en la lista → se abre una foto
- [ ] En el live: camarita sobre el video o en la barra → misma foto
- [ ] La foto se puede volver atrás
- [ ] En el NVR: **Pulso de relé** → mensaje OK o el `userMessage` del server
- [ ] Un pulso no se dispara dos veces solo
- [ ] **Real:** sin permiso / no soportado → mensaje, no crashea

## G. Alarmas y eventos

- [ ] Pestaña **Alarmas**
- [ ] Lista de alarmas y de eventos
- [ ] Alarma activa → **Ack** → queda reconocida
- [ ] Tirar hacia abajo refresca
- [ ] **Real:** el historial aparece aunque SignalR no mande nada

## H. Cosas que NO tienen que pasar

- [ ] No pide IP de la cámara
- [ ] No hay marca (Dahua, RISCO) como condición para que algo ande
- [ ] No se ve la contraseña ni el `sessionId` en logs
- [ ] No se guarda la clave
- [ ] HTTP solo para el video relay; login siempre HTTPS

---

## Orden práctico

1. Recorrer **A–G en demo** (un pase).  
2. Cuando haya server: repetir **A–G en real**, con foco en **D** (live MPEG-TS / H.265).  
3. Android primero. iOS cuando haya Mac.

Si un ítem de **Real** no se puede hacer todavía, dejalo vacío. No lo taches en demo.
