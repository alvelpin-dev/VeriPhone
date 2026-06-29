import Foundation

/// Construye la lista de pruebas aplicables a un `DeviceModel` concreto.
/// Ninguna prueba de hardware inexistente en el dispositivo debe aparecer:
/// por eso cada entrada se incluye condicionalmente según las capacidades
/// del modelo detectado.
enum DiagnosticTestFactory {

    static func buildTests(for device: DeviceModel) -> [DiagnosticTest] {
        var tests: [DiagnosticTest] = []

        // Batería
        tests.append(DiagnosticTest(
            id: "battery.health", title: "Batería", subtitle: "Nivel, estado de carga y salud aproximada",
            category: .battery, kind: .battery, isAutomatic: true,
            limitationNote: "iOS no expone el número de ciclos de carga ni la capacidad máxima exacta mediante API pública. Esa información solo aparece en Ajustes > Batería > Estado de la batería, leída por el propio sistema con acceso privado. Aquí se reporta el nivel y estado de carga actuales, que sí son públicos."
        ))

        // Pantalla
        tests.append(DiagnosticTest(
            id: "display.refresh", title: "Frecuencia de actualización", subtitle: "Tasa real medida con CADisplayLink",
            category: .display, kind: .display, isAutomatic: true, limitationNote: nil))
        tests.append(DiagnosticTest(
            id: "display.colors", title: "Píxeles muertos y manchas", subtitle: "Pantallas de color sólido",
            category: .display, kind: .colorPattern, isAutomatic: false, limitationNote: nil))
        tests.append(DiagnosticTest(
            id: "display.multitouch", title: "Multitáctil y ghost touch", subtitle: "Hasta 10 puntos de contacto",
            category: .display, kind: .multitouch, isAutomatic: false,
            limitationNote: "iOS no permite leer datos en bruto del controlador táctil; la detección de \"ghost touch\" se basa en observar toques que aparecen sin que el usuario los haya realizado durante la prueba manual."))

        // Biometría
        if device.hasFaceID {
            tests.append(DiagnosticTest(
                id: "biometrics.faceid", title: "Face ID", subtitle: "Autenticación facial",
                category: .biometrics, kind: .faceID, isAutomatic: true,
                limitationNote: "LocalAuthentication confirma que la autenticación facial funciona contra los rostros ya inscritos, pero no expone diagnósticos internos del sensor TrueDepth (eso requiere herramientas internas de Apple)."))
        }
        if device.hasTouchID {
            tests.append(DiagnosticTest(
                id: "biometrics.touchid", title: "Touch ID", subtitle: "Autenticación por huella",
                category: .biometrics, kind: .touchID, isAutomatic: true,
                limitationNote: "LocalAuthentication confirma que la autenticación dactilar funciona, pero no expone diagnósticos internos del sensor capacitivo."))
        }

        // Cámaras
        tests.append(DiagnosticTest(
            id: "camera.rear", title: "Cámara trasera", subtitle: "\(device.rearCameraCount) objetivo(s), enfoque y flash",
            category: .camera, kind: .rearCamera, isAutomatic: false, limitationNote: nil))
        tests.append(DiagnosticTest(
            id: "camera.front", title: "Cámara frontal", subtitle: "Captura y autoenfoque",
            category: .camera, kind: .frontCamera, isAutomatic: false, limitationNote: nil))

        // Audio
        tests.append(DiagnosticTest(
            id: "audio.microphone", title: "Micrófono(s)", subtitle: "\(device.microphoneCount) micrófono(s): grabación y nivel",
            category: .audio, kind: .microphone, isAutomatic: false, limitationNote: nil))
        tests.append(DiagnosticTest(
            id: "audio.speakers", title: "Altavoces", subtitle: device.hasStereoSpeakers ? "Auricular y altavoces estéreo" : "Auricular y altavoz inferior",
            category: .audio, kind: .speakers, isAutomatic: false, limitationNote: nil))

        // Botones
        tests.append(DiagnosticTest(
            id: "buttons.physical", title: "Botones físicos", subtitle: buttonsSubtitle(for: device),
            category: .buttons, kind: .buttons, isAutomatic: false,
            limitationNote: "No existe API pública para detectar pulsaciones del botón lateral, del botón de Acción o de Inicio; el volumen sí puede observarse públicamente mediante el cambio de volumen del sistema. Las demás pulsaciones se confirman de forma manual."))

        // Háptica
        tests.append(DiagnosticTest(
            id: "haptics.engine", title: "Motor háptico", subtitle: "Distintos patrones de vibración",
            category: .haptics, kind: .haptics, isAutomatic: false, limitationNote: nil))

        // Movimiento
        tests.append(DiagnosticTest(
            id: "motion.accelerometer", title: "Acelerómetro", subtitle: "Datos en tiempo real",
            category: .motion, kind: .accelerometer, isAutomatic: true, limitationNote: nil))
        if device.hasGyroscope {
            tests.append(DiagnosticTest(
                id: "motion.gyroscope", title: "Giroscopio", subtitle: "Datos en tiempo real",
                category: .motion, kind: .gyroscope, isAutomatic: true, limitationNote: nil))
        }
        if device.hasCompass {
            tests.append(DiagnosticTest(
                id: "motion.compass", title: "Brújula", subtitle: "Rumbo magnético/verdadero",
                category: .motion, kind: .compass, isAutomatic: true, limitationNote: nil))
        }
        tests.append(DiagnosticTest(
            id: "motion.gps", title: "GPS", subtitle: "Ubicación y precisión horizontal",
            category: .motion, kind: .gps, isAutomatic: true, limitationNote: nil))

        // Conectividad
        tests.append(DiagnosticTest(
            id: "connectivity.bluetooth", title: "Bluetooth", subtitle: "Estado del radio",
            category: .connectivity, kind: .bluetooth, isAutomatic: true, limitationNote: nil))
        tests.append(DiagnosticTest(
            id: "connectivity.wifi", title: "Wi-Fi", subtitle: "Estado de conexión",
            category: .connectivity, kind: .wifi, isAutomatic: true,
            limitationNote: "iOS no permite leer la intensidad de señal Wi-Fi desde una app de terceros; solo se confirma si hay una conexión activa."))
        tests.append(DiagnosticTest(
            id: "connectivity.cellular", title: "Datos móviles", subtitle: "Estado de conexión",
            category: .connectivity, kind: .cellular, isAutomatic: true,
            limitationNote: "iOS no expone el operador, la potencia de señal ni el tipo de red móvil mediante API pública en apps de terceros."))
        if device.hasNFC {
            tests.append(DiagnosticTest(
                id: "connectivity.nfc", title: "NFC", subtitle: "Disponibilidad de lectura NFC",
                category: .connectivity, kind: .nfc, isAutomatic: true, limitationNote: nil))
        }

        // Carga
        tests.append(DiagnosticTest(
            id: "charging.power", title: "Carga", subtitle: chargingSubtitle(for: device),
            category: .charging, kind: .charging, isAutomatic: true,
            limitationNote: "iOS no distingue públicamente entre carga por cable, inalámbrica Qi o MagSafe; solo informa si el dispositivo está cargando, completo o desconectado."))

        // Sensores
        tests.append(DiagnosticTest(
            id: "sensors.proximity", title: "Sensor de proximidad", subtitle: "Tapar el sensor durante una llamada simulada",
            category: .sensors, kind: .proximity, isAutomatic: false, limitationNote: nil))
        tests.append(DiagnosticTest(
            id: "sensors.ambientLight", title: "Sensor de luz ambiental", subtitle: "Cambiar entre zonas de luz y oscuridad",
            category: .sensors, kind: .ambientLight, isAutomatic: false,
            limitationNote: "No existe una API pública en iOS que devuelva el valor en lux del sensor de luz ambiental; solo puede confirmarse de forma manual observando el ajuste automático de brillo."))
        if device.hasLiDAR {
            tests.append(DiagnosticTest(
                id: "sensors.lidar", title: "Sensor LiDAR", subtitle: "Inicialización y reconstrucción de malla",
                category: .sensors, kind: .lidar, isAutomatic: true, limitationNote: nil))
        }
        if device.hasBarometer {
            tests.append(DiagnosticTest(
                id: "sensors.barometer", title: "Barómetro", subtitle: "Presión atmosférica en tiempo real",
                category: .sensors, kind: .barometer, isAutomatic: true, limitationNote: nil))
        }
        if device.hasDynamicIsland {
            tests.append(DiagnosticTest(
                id: "sensors.dynamicIsland", title: "Dynamic Island", subtitle: "Animación de demostración",
                category: .sensors, kind: .dynamicIsland, isAutomatic: true, limitationNote: nil))
        }
        if device.hasAlwaysOnDisplay {
            tests.append(DiagnosticTest(
                id: "sensors.alwaysOn", title: "Always-On Display", subtitle: "Compatibilidad del panel",
                category: .sensors, kind: .alwaysOnDisplay, isAutomatic: true,
                limitationNote: "No existe API pública para forzar o verificar el comportamiento real de Always-On con la pantalla bloqueada; se confirma únicamente que el hardware del modelo lo admite."))
        }

        return tests
    }

    private static func buttonsSubtitle(for device: DeviceModel) -> String {
        var parts = ["Volumen +", "Volumen −", "Botón lateral"]
        if device.hasActionButton { parts.append("Botón de Acción") }
        if device.hasHomeButton { parts.append("Botón Home") }
        if device.hasMuteSwitch { parts.append("Interruptor de silencio") }
        return parts.joined(separator: ", ")
    }

    private static func chargingSubtitle(for device: DeviceModel) -> String {
        var parts = [device.connector.rawValue]
        if device.supportsWirelessCharging { parts.append("inalámbrica") }
        if device.supportsMagSafe { parts.append("MagSafe") }
        return parts.joined(separator: " · ")
    }
}
