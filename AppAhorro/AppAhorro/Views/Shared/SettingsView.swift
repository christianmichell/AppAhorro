import SwiftUI

/// Settings screen allowing configuration of privacy preferences and data management.
struct SettingsView: View {
    @State private var apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    @State private var exportMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Integraciones de IA")) {
                    SecureField("OpenAI API Key", text: $apiKey)
                    Text("La clave se almacena en el llavero utilizando Keychain al ejecutar la app real.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text("Privacidad")) {
                    Toggle("Adjuntar ubicación automáticamente", isOn: .constant(false))
                        .disabled(true)
                    Text("Esta versión de demostración no solicita permisos de ubicación automáticamente.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text("Datos")) {
                    Button("Exportar respaldo JSON") {
                        exportMessage = "Respaldo exportado a Archivos en la aplicación real."
                    }
                }

                if let exportMessage {
                    Section {
                        Text(exportMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
