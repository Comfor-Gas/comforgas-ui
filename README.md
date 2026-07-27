# Comfor Gas — Login (Flutter)

Pantalla de login **solo visual** (sin lógica), modularizada.

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

## Puedes editar el código en tu editor (VS Code o el propio Android Studio) y ver el resultado en el celular emulado, siempre que la app esté corriendo en ese emulador.
1. Arrancas la app una vez en el emulador (flutter run -d emulator-5554 o el botón ▶). Se abre en el Pixel.
2. Dejas eso corriendo y editas tu código.
3. Guardas (Ctrl + S) y haces hot reload → el cambio aparece en el emulador en un segundo.

## Pasos en Android Studio
1. Ejecuta `flutter pub get`.
2. Corre la app (`flutter run`).

Las fuentes Plus Jakarta Sans / Inter se cargan automáticamente vía `google_fonts` (requiere conexión la primera vez).
