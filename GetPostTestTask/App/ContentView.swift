//
//  ContentView.swift
//  GetPostTestTask
//
//  Created by Denis Dareuskiy on 3.10.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = MainViewModel()
    var body: some View {
        MainView()
            .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
