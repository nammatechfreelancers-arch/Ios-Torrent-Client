// DeveloperView.swift
import SwiftUI

public struct DeveloperView: View {
    @State private var vm = DeveloperViewModel()

    public var body: some View {
        NavigationStack {
            List {
                // Engine Stats
                Section("Engine") {
                    Text(vm.engineStats)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                // Active Torrents
                Section("Active Torrents") {
                    let active = TorrentService.shared.torrents.filter { $0.isActive }
                    if active.isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    } else {
                        ForEach(active) { t in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.name).font(.caption.weight(.semibold)).lineLimit(1)
                                Text("↓ \(Formatters.speed(t.downloadSpeed))  ↑ \(Formatters.speed(t.uploadSpeed))  \(Formatters.percent(t.progress))")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Log
                Section {
                    if vm.logLines.isEmpty {
                        Text("No logs yet.").foregroundStyle(.secondary).font(.caption)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(vm.logLines.reversed(), id: \.self) { line in
                                    Text(line)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                    }
                } header: {
                    HStack {
                        Text("Logs")
                        Spacer()
                        Button("Clear") { vm.clearLogs() }
                            .font(.caption)
                    }
                }

                // Network
                Section("Network") {
                    let net = NetworkMonitor.shared
                    LabeledContent("Connected", value: net.isConnected ? "Yes" : "No")
                    LabeledContent("Cellular",  value: net.isExpensive ? "Yes" : "No")
                    LabeledContent("Low Data",  value: net.isConstrained ? "Yes" : "No")
                }
            }
            .navigationTitle("Developer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.addLog("Manual log entry at \(Date().formatted())")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear { vm.onAppear() }
        .onDisappear { vm.onDisappear() }
    }
}
