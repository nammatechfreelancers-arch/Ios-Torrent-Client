// SettingsView.swift
import SwiftUI

public struct SettingsView: View {
    @State private var vm = SettingsViewModel()

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $vm.settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Accent Color", selection: $vm.settings.accentColor) {
                        ForEach(AccentColor.allCases, id: \.self) {
                            Label($0.rawValue, systemImage: "circle.fill")
                                .foregroundStyle($0.color)
                                .tag($0)
                        }
                    }
                    Toggle("Show Thumbnails", isOn: $vm.settings.showThumbnails)
                }

                // MARK: Network
                Section("Network") {
                    Toggle("Wi-Fi Only", isOn: $vm.settings.wifiOnly)
                    Toggle("Allow Cellular", isOn: $vm.settings.allowCellular)
                    Toggle("DHT", isOn: $vm.settings.dhtEnabled)
                    Toggle("PEX", isOn: $vm.settings.pexEnabled)
                    Toggle("Local Service Discovery", isOn: $vm.settings.lsdEnabled)
                    Stepper("Max Connections: \(vm.settings.maxConnections)",
                            value: $vm.settings.maxConnections, in: 10...500, step: 10)
                    Stepper("Max Active Downloads: \(vm.settings.maxActiveDownloads)",
                            value: $vm.settings.maxActiveDownloads, in: 1...10)
                }

                // MARK: Speed Limits
                Section("Speed Limits (KB/s, 0 = unlimited)") {
                    HStack {
                        Text("Download")
                        Spacer()
                        TextField("0", value: $vm.settings.maxDownloadSpeed, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Upload")
                        Spacer()
                        TextField("0", value: $vm.settings.maxUploadSpeed, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                // MARK: Storage
                Section("Storage") {
                    HStack {
                        Text("Downloads Size")
                        Spacer()
                        Text(vm.totalDownloadsSize).foregroundStyle(.secondary)
                    }
                    Button("Clear All Downloads", role: .destructive) {
                        Task { await vm.clearAllData() }
                    }
                }

                // MARK: Notifications
                Section("Notifications") {
                    Toggle("On Complete", isOn: $vm.settings.notifyOnComplete)
                    Toggle("On Error", isOn: $vm.settings.notifyOnError)
                    Toggle("On Start", isOn: $vm.settings.notifyOnStart)
                }

                // MARK: Haptics
                Section("Haptics") {
                    Toggle("Enable Haptics", isOn: $vm.settings.hapticsEnabled)
                }

                // MARK: Developer
                Section("Developer") {
                    Toggle("Developer Mode", isOn: $vm.settings.developerModeEnabled)
                    if vm.settings.developerModeEnabled {
                        Toggle("Verbose Logging", isOn: $vm.settings.verboseLogging)
                    }
                }

                // MARK: Reset
                Section {
                    Button("Reset to Defaults", role: .destructive) { vm.reset() }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onFirstAppear { await vm.loadDiskUsage() }
    }
}
