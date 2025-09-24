import SwiftUI
import PhotosUI
import UIKit

/// Presents the capture and upload flow leveraging the AI pipeline.
struct ReceiptCaptureSheet: View {
    @EnvironmentObject private var store: ReceiptStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReceiptUploadViewModel()

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Documento")) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .padding(.vertical)
                    } else {
                        Text("Selecciona o captura una imagen de tu boleta para iniciar el análisis.")
                            .foregroundStyle(.secondary)
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Elegir desde galería", systemImage: "photo")
                    }

                    Button {
                        showingCamera = true
                    } label: {
                        Label("Tomar fotografía", systemImage: "camera")
                    }
                }

                Section(header: Text("Detalles opcionales")) {
                    TextField("Descripción", text: $viewModel.description, axis: .vertical)
                    DatePicker("Fecha de pago", selection: $viewModel.captureDate, displayedComponents: [.date])
                    TextField("Ubicación", text: $viewModel.locationDescription)
                }

                Section {
                    Button {
                        guard let image = selectedImage else { return }
                        viewModel.submit(image: image)
                    } label: {
                        if case .processing = viewModel.state {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Analizar boleta")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(selectedImage == nil || (viewModel.state == .processing))
                }

                if case let .failure(error) = viewModel.state {
                    Section {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Nueva boleta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onChange(of: selectedItem) { newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                        }
                    }
                }
            }
            .onChange(of: viewModel.state) { state in
                if case .success = state {
                    store.refresh()
                    dismiss()
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
            }
        }
        .onAppear {
            viewModel.bind(to: store)
            viewModel.reset()
        }
    }
}

private struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
    }
}
