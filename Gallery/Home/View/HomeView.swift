//
//  HomeView.swift
//  Gallery
//
//  Created by Dominik Kohlman on 04.01.2022.
//

import SwiftUI
import URLCache

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .onAppear {
                        viewModel.loadData.send()
                    }
            case .loaded(let photosData):
                let columns = [
                    GridItem(.adaptive(minimum: 150))
                ]

                NavigationView {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(photosData, id: \.self) { photoData in
                                ZStack(alignment: .bottom) {
                                    Image(uiImage: UIImage(data: photoData.data) ?? UIImage(systemName: "photo")!)
                                        .resizable()
                                        .scaledToFit()
                                    Group {
                                        Text("Fetched from ")
                                            .foregroundColor(.white)
                                        +
                                        Text(photoData.source.rawValue.capitalized)
                                            .foregroundColor(photoData.source == .cache ? .green : .red)
                                    }
                                    .padding(3)
                                    .font(.caption)
                                    .background(Color.black.opacity(0.6))
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .navigationBarTitle("Gallery")
                    .navigationBarItems(
                        leading: Button("Clear cache") {
                            viewModel.clearCache.send()
                        }
                        .alert(isPresented: $viewModel.showCacheAlert) {
                            Alert(
                                title: Text("Cache is cleared"),
                                dismissButton: .default(Text("OK"))
                            )
                        },
                        trailing: Button("Reload") {
                            viewModel.loadData.send()
                        }
                    )
                }
            }
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("Something went wrong"),
                primaryButton: .default(
                    Text("Try again"),
                    action: {
                        viewModel.loadData.send()
                    }
                ),
                secondaryButton: .cancel()
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
