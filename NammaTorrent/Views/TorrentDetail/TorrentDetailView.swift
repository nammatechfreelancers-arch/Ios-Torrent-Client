// TorrentDetailView.swift
import SwiftUI

public struct TorrentDetailView: View {
    let torrentID: UUID
    @State private var vm: TorrentDetailViewModel

    public init(torrentID: UUID) {
        self.torrentID = torrentID
        _vm = State(initialValue: TorrentDetailViewModel(torrentID: torrentID))
    }

    public var body: some View {
        Group {
            if let torrent = vm.torrent {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header card
                        VStack(spacing: 12) {
                            ProgressRing(progress: torrent.progress, size: 80, lineWidth: 6,
                                         color: .statusColor(for: torrent.status))
                            Text(torrent.name).font(.headline).multilineTextAlignment(.center)
                            StatusBadge(status: torrent.status)
                            HStack(spacing: 24) {
                                SpeedBadge(speed: torrent.downloadSpeed, direction: .down)
                                SpeedBadge(speed: torrent.uploadSpeed, direction: .up)
                            }
                            SpeedGraph(samples: vm.speedHistory, color: .blue)
                                .padding(.horizontal)
                        }
                        .padding()
                        .cardStyle()
                        .padding(.horizontal)

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCell(label: "Downloaded", value: Formatters.fileSize(torrent.downloadedSize))
                            StatCell(label: "Uploaded",   value: Formatters.fileSize(torrent.uploadedSize))
                            StatCell(label: "Size",       value: Formatters.fileSize(torrent.totalSize))
                            StatCell(label: "Ratio",      value: Formatters.ratio(torrent.ratio))
                            StatCell(label: "Seeds",      value: "\(torrent.seedCount)")
                            StatCell(label: "Peers",      value: "\(torrent.peerCount)")
                            StatCell(label: "ETA",        value: Formatters.eta(torrent.eta))
                            StatCell(label: "Added",      value: torrent.addedDate.timeAgo)
                        }
                        .padding(.horizontal)

                        // Tabs
                        Picker("Tab", selection: $vm.selectedTab) {
                            Text("Files").tag(0)
                            Text("Peers").tag(1)
                            Text("Trackers").tag(2)
                            Text("Pieces").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch vm.selectedTab {
                        case 0: FilesTabView(files: torrent.files)
                        case 1: PeersTabView(peers: torrent.peers)
                        case 2: TrackersTabView(trackers: torrent.trackers)
                        case 3: PiecesTabView(pieces: vm.pieces)
                        default: EmptyView()
                        }
                    }
                    .padding(.vertical)
                }
            } else {
                ContentUnavailableView("Torrent not found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let torrent = vm.torrent {
                    Button {
                        Task {
                            torrent.isActive ? await vm.pause() : await vm.resume()
                        }
                    } label: {
                        Image(systemName: torrent.isActive ? "pause.fill" : "play.fill")
                    }
                }
            }
        }
        .onAppear { vm.onAppear() }
        .onDisappear { vm.onDisappear() }
    }
}

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.subheadline.weight(.semibold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .cardStyle()
    }
}
