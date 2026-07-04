// HomeView.swift
import SwiftUI

public struct HomeView: View {
    @State private var vm = HomeViewModel()

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if vm.filteredTorrents.isEmpty && !TorrentService.shared.isLoading {
                        EmptyStateView(
                            icon: "arrow.down.circle",
                            title: "No Torrents",
                            subtitle: "Add a magnet link or .torrent file to get started.",
                            action: { vm.showAddSheet = true },
                            actionLabel: "Add Torrent"
                        )
                    } else {
                        List {
                            ForEach(vm.filteredTorrents) { torrent in
                                NavigationLink(value: torrent) {
                                    TorrentRowView(torrent: torrent)
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await vm.remove(id: torrent.id, deleteFiles: false) }
                                    } label: { Label("Remove", systemImage: "trash") }

                                    Button {
                                        Task { await vm.remove(id: torrent.id, deleteFiles: true) }
                                    } label: { Label("Delete", systemImage: "trash.fill") }
                                        .tint(.red)
                                }
                                .swipeActions(edge: .leading) {
                                    if torrent.isActive {
                                        Button { Task { await vm.pause(id: torrent.id) } } label: {
                                            Label("Pause", systemImage: "pause.fill")
                                        }.tint(.orange)
                                    } else {
                                        Button { Task { await vm.resume(id: torrent.id) } } label: {
                                            Label("Resume", systemImage: "play.fill")
                                        }.tint(.green)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .searchable(text: $vm.searchText, prompt: "Search torrents")
                    }
                }

                FloatingActionButton(icon: "plus") { vm.showAddSheet = true }
                    .padding(24)
            }
            .navigationTitle("NammaTorrent")
            .navigationDestination(for: TorrentModel.self) { torrent in
                TorrentDetailView(torrentID: torrent.id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SpeedBadge(speed: vm.totalDownloadSpeed, direction: .down)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $vm.sortOrder) {
                            ForEach(HomeViewModel.SortOrder.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                    } label: { Image(systemName: "arrow.up.arrow.down") }
                }
            }
            .sheet(isPresented: $vm.showAddSheet) {
                AddTorrentSheet(vm: vm)
            }
            .alert("Error", isPresented: .constant(vm.error != nil), presenting: vm.error) { _ in
                Button("OK") { vm.error = nil }
            } message: { e in Text(e.message) }
        }
    }
}
