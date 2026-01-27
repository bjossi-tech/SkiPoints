import SwiftUI

struct SettingsView: View {
    private static let fisURL = URL(string: "https://www.fis-ski.com")

    var body: some View {
        List {
            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                if let url = Self.fisURL {
                    Link(destination: url) {
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
                    Text("Björn")
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
