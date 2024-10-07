//
//  MainView.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import SwiftUI
import AVFoundation

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showCamera: Bool = false
    @State private var selectedPhoto: UIImage? = nil
    @State private var selectedPhotoID: Int? = nil
    @State private var responseMessage: String? = nil
    @State private var showAlert: Bool = false
    @State private var developerName: String = ""
    @State private var isDeveloperNameEntered: Bool = false
    @FocusState private var isDeveloperNameFocused: Bool

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Загрузка данных...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding()
                } else if !isDeveloperNameEntered {
                    TextField("Введите ФИО разработчика", text: $developerName, onCommit: {
                        print("Enter pressed, developerName: \(developerName)")
                        isDeveloperNameEntered = true
                        isDeveloperNameFocused = false
                    })
                    .focused($isDeveloperNameFocused)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onAppear {
                        isDeveloperNameFocused = true
                    }
                } else {
                    List {
                        ForEach(viewModel.photos, id: \.id) { photo in
                            Button(action: {
                                selectedPhotoID = photo.id
                                checkCameraAccess()
                            }) {
                                HStack(spacing: 16) {
                                    Text(photo.name)
                                        .foregroundStyle(Color.primary)
                                    
                                    Image(systemName: photo.image != nil && !photo.image!.isEmpty ? "checkmark" : "xmark")
                                        .foregroundStyle(photo.image != nil && !photo.image!.isEmpty ? .green : .red)
                                }
                            }
                            .onAppear {
                                if photo == viewModel.photos.last && viewModel.hasMorePages {
                                    print("Loading more photos for page \(viewModel.currentPage)")
                                    viewModel.loadMorePhotos(page: viewModel.currentPage)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Photos")
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedPhoto)
                    .onDisappear {
                        if let image = selectedPhoto, let photoID = selectedPhotoID,
                           let photoName = viewModel.photos.first(where: { $0.id == photoID })?.name {
                            // Вызов метода uploadPhoto без замыкания
                            viewModel.uploadPhoto(name: photoName, photoID: photoID, image: image)
                        }
                    }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertStatus ?? "Response"),
                    message: Text("\(viewModel.alertMessage ?? "No message")"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            if viewModel.photos.isEmpty {
                print("Loading all photos")
                viewModel.loadAllPhotos()
            }
        }
    }

    private func checkCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.showCamera = true
                }
            } else {
                DispatchQueue.main.async {
                    responseMessage = "Доступ к камере не предоставлен."
                    showAlert = true
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }
}

#Preview {
    MainView()
}
