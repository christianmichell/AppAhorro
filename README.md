# AppAhorro

AppAhorro es una aplicación iOS escrita en SwiftUI que permite digitalizar, organizar y analizar boletas y facturas utilizando almacenamiento local y análisis con modelos de OpenAI. Incluye un tablero analítico con gráficas, un flujo de captura con cámara o biblioteca, y un asistente conversacional para consultar gastos específicos.

## Características clave

- **Ingesta flexible de documentos**: captura desde la cámara, fotos existentes o archivos y almacenamiento en el sandbox del usuario.
- **Análisis mediante IA**: extracción de metadatos de boletas (comercio, monto, IVA, ubicación, palabras clave) llamando a modelos visuales de OpenAI.
- **Organización automática**: categorización por rubros estándar, etiquetado inteligente y búsqueda semántica.
- **Dashboard financiero**: visualización de gastos por categoría, tendencia diaria y nube de palabras clave.
- **Asistente de consultas**: interfaz conversacional para responder preguntas sobre gastos específicos utilizando heurísticas locales.
- **Informes rápidos**: vistas tradicionales para listar, filtrar y revisar cada boleta con sus metadatos.

## Requisitos

- Xcode 15 o superior.
- iOS 16 o superior como destino de despliegue.
- Swift 5.8+
- Opcional: variable de entorno `OPENAI_API_KEY` para habilitar el análisis real con OpenAI.

## Configuración del proyecto

1. Clona el repositorio y abre `AppAhorro.xcodeproj` en Xcode.
2. Configura un equipo de desarrollo (Signing & Capabilities) si deseas ejecutar en dispositivo.
3. Opcional: agrega tu clave de OpenAI en el entorno de ejecución (por ejemplo en *Edit Scheme > Run > Arguments* como variable `OPENAI_API_KEY`).
4. Compila y ejecuta en un simulador iOS 16 o superior.

## Estructura principal

- `AppAhorroApp.swift`: punto de entrada que inyecta los `EnvironmentObject` principales.
- `Models/`: modelos de dominio `Receipt`, `ReceiptCategory`, `AnalyticsSummary` y queries.
- `Services/`: persistencia de archivos, analizador OpenAI, motor de consultas y servicio de analítica.
- `ViewModels/`: lógica de presentación para dashboard, lista, carga y asistente.
- `Views/`: interfaz construida en SwiftUI dividida por áreas (dashboard, boletas, componentes compartidos).
- `Resources/`: activos de la app (Assets catalog e Info.plist).
- `AppAhorroTests/` y `AppAhorroUITests/`: pruebas unitarias y UI.

## Pruebas

Ejecuta las pruebas desde Xcode (`⌘U`) o con `xcodebuild`:

```bash
xcodebuild test -scheme AppAhorro -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Notas de seguridad y privacidad

- Los archivos originales y miniaturas se almacenan en el directorio `Documents` del contenedor de la app.
- No se envían datos a OpenAI si no se define `OPENAI_API_KEY`; en ese caso se usa una respuesta simulada.
- Recuerda cumplir la normativa local para el almacenamiento de documentos tributarios.
