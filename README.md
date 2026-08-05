# Comfor Gas — (Flutter)



## Estructura

```
lib/
  main.dart
  theme/
    app_colors.dart
    app_text_styles.dart
  screens/
    login_screen.dart
  widgets/
    logo_header.dart
    labeled_text_field.dart
    fingerprint_button.dart
    primary_button.dart
    forgot_password_link.dart
    footer_decoration.dart
assets/
  images/
    logo_comfor_gas.png
    fingerprint.png
```

---

## 1. Requisitos previos (instalación desde cero)

Necesitás tener instalado:

1. **Flutter SDK** (canal stable). Este proyecto usa Dart `>=3.0.0 <4.0.0`.
   - Descarga: https://docs.flutter.dev/get-started/install
   - Verificá la instalación con:
     ```bash
     flutter --version
     ```

2. **Un editor**: VS Code (con la extensión Flutter/Dart) o Android Studio.

3. **Google Chrome** (para correr la versión web).

4. **Android Studio** (para la versión Android), con:
   - Android SDK instalado (desde el propio Android Studio: *More Actions → SDK Manager*).
   - Un emulador creado (*More Actions → Virtual Device Manager → Create Device*), o un celular físico con **depuración USB** habilitada.

5. Corré el chequeo de salud de Flutter para confirmar que todo está bien configurado:
   ```bash
   flutter doctor
   ```
   Solucioná cualquier ítem marcado con `[✗]` antes de continuar (licencias de Android, variables de entorno, etc.). Si te pide aceptar licencias de Android:
   ```bash
   flutter doctor --android-licenses
   ```

---

## 2. Preparar el proyecto

1. Descomprimí/cloná el proyecto y entrá a la carpeta:
   ```bash
   cd nombre-de-carpeta
   ```

2. Instalá las dependencias:
   ```bash
   flutter pub get
   ```

3. (Opcional) Verificá qué dispositivos detecta Flutter (emuladores, navegador, celular conectado):
   ```bash
   flutter devices
   ```

> Las fuentes Plus Jakarta Sans / Inter se cargan automáticamente vía `google_fonts` (requiere conexión a internet la primera vez que se compila).

---

## 3. Levantar la versión Web en el puerto 5000

1. Asegurate de tener habilitado el soporte web (una sola vez, por si no está):
   ```bash
   flutter config --enable-web
   ```

2. Corré la app en Chrome especificando el puerto:
   ```bash
   flutter run -d chrome --web-port=5000
   ```

3. Se abrirá automáticamente en `http://localhost:5000`.

Alternativa: si querés compilar una versión de producción (archivos estáticos) y servirla vos mismo en el puerto 5000:
```bash
flutter build web
cd build/web
python3 -m http.server 5000
```
Y luego abrís `http://localhost:5000` en el navegador.

---

## 4. Levantar la versión Android (emulador o celular)

### Opción A: Emulador
1. Abrí Android Studio → *Virtual Device Manager* → creá o iniciá un emulador (por ejemplo un Pixel).
2. Con el emulador corriendo, confirmá que Flutter lo detecta:
   ```bash
   flutter devices
   ```
3. Ejecutá la app:
   ```bash
   flutter run -d emulator-5554
   ```
   (reemplazá `emulator-5554` por el ID que te haya mostrado `flutter devices`; si solo tenés un dispositivo activo, alcanza con `flutter run`).

### Opción B: Celular físico
1. Habilitá **Opciones de desarrollador** en el celular (Ajustes → Acerca del teléfono → tocar 7 veces "Número de compilación").
2. Activá **Depuración USB** dentro de Opciones de desarrollador.
3. Conectá el celular por USB y aceptá el permiso de depuración que aparece en pantalla.
4. Verificá que aparece en la lista:
   ```bash
   flutter devices
   ```
5. Ejecutá:
   ```bash
   flutter run
   ```

### Generar el APK (para instalar sin cable)
```bash
flutter build apk --release
```
El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. Pasalo al celular e instalalo manualmente.

---

## 5. Flujo de trabajo con hot reload

Podés editar el código en tu editor (VS Code o Android Studio) y ver el resultado en vivo mientras la app está corriendo:

1. Arrancás la app una vez (en Chrome con `--web-port=5000`, o en el emulador/celular con `flutter run`).
2. Dejás ese proceso corriendo y editás tu código.
3. Guardás (`Ctrl + S`) y hacés hot reload → el cambio aparece al instante:
   - En la terminal donde corre `flutter run`, apretá la tecla `r` (hot reload) o `R` (hot restart).
   - En VS Code/Android Studio, usá el botón de hot reload (⚡).

---

## 6. Datos del proyecto

- **Nombre del paquete (Android)**: `com.comforgas.app`
- **Java/Kotlin**: JVM 17
- **Dependencias principales**: `flutter_secure_storage`, `http`, `provider`
