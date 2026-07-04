// SearchView.swift
import SwiftUI

public struct SearchView: View {
    @State private var vm = SearchViewModel()

    public var body: some View {
        NavigationStack {
            Group {
                if vm.query.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Search Torrents",
                        subtitle: "Search by name or info hash.\nPaste a magnet link to add directly."
                    )
                } else if vm.results.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        subtitle: "No torrents match \"\(vm.query)\"."
                    )
                } else {
                    List {
                        ForEach(vm.results) { torrent in
                            NavigationLink(value: torrent) {
                                TorrentRowView(torrent: torrent)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: TorrentModel.self) { torrent in
                TorrentDetailView(torrentID: torrent.id)
            }
            .searchable(text: $vm.query, prompt: "Name, hash, or magnet link")
            .onChange(of: vm.query) { _, _ in vm.search() }
            .onSubmit(of: .search) {
                Task {
                    let added = await vm.handlePaste(vm.query)
                    if added { vm.clear() }
                }
            }
        }
    }
}
