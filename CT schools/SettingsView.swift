import SwiftUI

struct SettingsView: View {
    @Bindable var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEmailUnavailableAlert = false
    @State private var showingCopyEmailAlert = false
    
    private let supportEmail = "beckford.shanique93@gmail.com"
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    var body: some View {
        NavigationStack {
            List {
                // Appearance Settings
                Section {
                    HStack {
                        Label("Theme", systemImage: "paintbrush.fill")
                        Spacer()
                        Picker("Theme", selection: $themeManager.selectedTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                HStack {
                                    Image(systemName: theme.icon)
                                    Text(theme.rawValue)
                                }
                                .tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose your preferred color scheme for the app")
                }
                
                // App Information
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("App Information")
                }
                
                // Support & Feedback
                Section {
                    Button {
                        sendEmail(subject: "CT Schools App - Support Request")
                    } label: {
                        HStack {
                            Label("Contact Support", systemImage: "questionmark.circle.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        sendEmail(subject: "CT Schools App - Feedback")
                    } label: {
                        HStack {
                            Label("Send Feedback", systemImage: "envelope.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        sendEmail(subject: "CT Schools App - Bug Report")
                    } label: {
                        HStack {
                            Label("Report a Bug", systemImage: "ladybug.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Support & Feedback")
                } footer: {
                    Text("Tap any option above to send us an email")
                        .font(.caption)
                }
                
                // About
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About CT Schools")
                            .font(.headline)
                        Text("This app provides information about Connecticut schools using publicly available data from data.ct.gov.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About")
                }
                
                // Data Source
                Section {
                    Link(destination: URL(string: "https://data.ct.gov")!) {
                        HStack {
                            Label("Connecticut Open Data", systemImage: "globe")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Data Source")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Email Not Available", isPresented: $showingEmailUnavailableAlert) {
                Button("Copy Email Address") {
                    UIPasteboard.general.string = supportEmail
                    showingCopyEmailAlert = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("No email account is configured on this device. You can copy our support email address to contact us through another app.")
            }
            .alert("Email Copied", isPresented: $showingCopyEmailAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Support email address has been copied to your clipboard.")
            }
        }
    }
    
    // Helper function to compose email
    private func sendEmail(subject: String) {
        let body = """
        
        
        ---
        App Version: \(appVersion)
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body
        
        if let url = URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)") {
            // Check if Mail app can open the URL
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Show alert if email is not configured
                showingEmailUnavailableAlert = true
            }
        }
    }
}

#Preview {
    SettingsView(themeManager: ThemeManager())
}
