import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                Link(destination: URL(string: "https://www.fis-ski.com")!) {
                    HStack {
                        Label("FIS Website", systemImage: "globe")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
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
