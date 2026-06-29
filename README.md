# VeriPhone

App nativa SwiftUI (MVVM) para diagnosticar un iPhone de segunda mano antes de comprarlo: detecta el modelo exacto, genera automáticamente solo las pruebas aplicables a ese hardware, y produce un informe final exportable a PDF.

## Abrir el proyecto

1. Requiere **Xcode 16+** y **iOS 17+** como destino mínimo (`IPHONEOS_DEPLOYMENT_TARGET = 17.0`).
2. Abre `VeriPhone.xcodeproj` con Xcode (en macOS — este proyecto se generó en un entorno Windows sin Xcode disponible para compilar/verificar localmente; revisa la compilación al abrirlo).
3. Selecciona tu equipo de firma (`DEVELOPMENT_TEAM`) en el target `VeriPhone` → *Signing & Capabilities*, porque la mayoría de pruebas (cámara, biometría, ARKit, CoreMotion…) requieren un dispositivo físico.
4. Si vas a probar la prueba de NFC en un dispositivo real más allá de comprobar disponibilidad, añade la capability **Near Field Communication Tag Reading** desde *Signing & Capabilities* (Xcode generará el entitlement automáticamente).

## Estructura

```
VeriPhone/
  App/                  Punto de entrada (@main)
  Models/                DeviceModel, DeviceDatabase, DiagnosticModels
  Managers/              Un manager por subsistema de hardware (batería, cámara, audio, motion, biometría, ARKit, conectividad, sensores, háptica)
  Diagnostics/           DiagnosticTestFactory: construye la lista de pruebas según el DeviceModel detectado
  ViewModels/            HomeViewModel, DiagnosticViewModel
  Views/                 Home, lista de diagnóstico, detalle de cada prueba, informe final
  Utilities/             PDFExporter
  Resources/             Info.plist, Assets.xcassets
generate_project.py      Regenera VeriPhone.xcodeproj/project.pbxproj a partir del árbol de archivos
```

Si añades o eliminas archivos `.swift`, vuelve a ejecutar `python generate_project.py` desde la raíz del repositorio para mantener el `.xcodeproj` sincronizado.

## Limitaciones de APIs públicas (intencionadas, no bugs)

Cada una de estas limitaciones aparece también documentada dentro de la propia app, en la prueba correspondiente (sección "Limitación de API pública"):

- **Número de serie real**: no accesible por apps de terceros (privacidad de Apple).
- **Ciclos de carga / capacidad máxima de batería**: no expuestos por API pública; solo visibles en Ajustes > Batería.
- **Diagnóstico interno de Face ID / Touch ID**: `LocalAuthentication` solo confirma que la autenticación funciona, no el estado de fábrica del sensor.
- **Botón lateral, botón de Acción, botón Home, interruptor de silencio**: sin API pública de detección; se verifican con confirmación manual del usuario.
- **Intensidad de señal Wi-Fi / operador y red móvil**: no expuestos a apps de terceros.
- **Tipo de carga (cable/inalámbrica/MagSafe)**: iOS solo informa "cargando/completa/desconectado", sin distinguir el método.
- **Sensor de luz ambiental en lux**: sin API pública; se verifica mediante confirmación manual observando el autobrillo.
- **Comportamiento real de Always-On Display con la pantalla bloqueada**: no verificable programáticamente desde una app en primer plano.

## Pendiente de verificación en Xcode real

Este proyecto se ha construido y revisado exhaustivamente a nivel de código (imports, ciclos de retención, concurrencia con `@MainActor`, APIs vigentes en iOS 17+), pero **no ha podido compilarse en un toolchain de Xcode real** porque se generó en un entorno Windows. Al abrirlo, revisa cualquier advertencia o error puntual de compilación que Xcode señale (por ejemplo, ajustes de firma o capacidades) antes de ejecutarlo en un dispositivo.
