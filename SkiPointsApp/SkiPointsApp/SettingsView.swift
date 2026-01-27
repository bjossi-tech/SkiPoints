import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text(AppConstants.AppInfo.version)
                        .foregroundStyle(.secondary)
                }

                if let fisURL = URL(string: AppConstants.AppInfo.fisWebsiteURL) {
                    Link(destination: fisURL) {
                        HStack {
                            Label("FIS Website", systemImage: "globe")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("App") {
                HStack {
                    Label("Developer", systemImage: "person")
                    Spacer()
                    Text(AppConstants.AppInfo.developer)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Text("SkiPoints calculates FIS alpine skiing points using the official FIS formula. Data is sourced from fis-ski.com.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Data")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
