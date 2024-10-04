//
//  MainView.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        Button {
            viewModel.clearCache()
        } label: {
            Text("Clear")
                .foregroundStyle(.red)
        }
        NavigationView {
            List {
                ForEach(viewModel.photos, id: \.id) { photo in
                    NavigationLink(destination: DetailView(photo: photo)) {
                        HStack(spacing: 16) {
                            Text(photo.name)
                            
                            Image(systemName: photo.image != nil && !photo.image!.isEmpty ? "checkmark" : "xmark")
                                .foregroundStyle(photo.image != nil && !photo.image!.isEmpty ? .green : .red)
                        }
                    }
                    .onAppear {
                        // Проверка, если это последний элемент, чтобы загрузить больше
                        if photo == viewModel.photos.last {
                            viewModel.loadMorePhotos(page: viewModel.currentPage)
                        }
                    }
                }
            }
            .navigationTitle("Photos")
        }
        .onAppear {
            viewModel.loadAllPhotos() // Начинаем загрузку всех страниц при появлении
        }
    }
}

#Preview {
    MainView()
}
