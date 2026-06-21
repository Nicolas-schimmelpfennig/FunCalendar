//
//  AboutView.swift
//  FunCalendar
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: StoreViewModel

    private let supportURL = "https://nicolas-schimmelpfennig.github.io/FunCalendar/"
    private let privacyURL = "https://nicolas-schimmelpfennig.github.io/FunCalendar/privacy.html"
    private let contactEmail = "schimmelpfennig.nicolas@gmail.com"
    private let appleEULAURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

    @Environment(\.openURL) private var openURL

    @State private var showPasswordPrompt = false
    @State private var passwordInput = ""
    @State private var showWrongPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Text("About")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    // MARK: Note from developer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A note from me")
                            .font(.headline)
                        Text("Thanks for downloading my little app! Originally this project wasn’t supposed to be anything more than a little design challenge to create a simple, fun utility that does one thing and one thing only. But then a few friends of mine wanted to get the app on their devices also and here we are :) ")
                            .font(.body)
                            .foregroundStyle(.secondary)
        
                    }

                    Divider()
                    // MARK: Why not Free
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why not make it free?")
                            .font(.headline)
                        Text("Simple - Distributing apps on the App Store costs money. I decided to add the in-app purchase as a way to help offset the cost of keeping the app live on the App Store. So if you get any value out of my little experiment, I’d really appreciate your support! <3")
                            .font(.body)
                            .foregroundStyle(.secondary)
        
                    }

                    Divider()

                    // MARK: Support
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Support")
                            .font(.headline)
                        Text("For help, feedback, or bug reports, visit the support page or send an email directly.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 16) {
                            Link("Support Page", destination: URL(string: supportURL)!)
                                .font(.subheadline)
                            Button("Email Support") {
                                if let url = URL(string: "mailto:\(contactEmail)") {
                                    openURL(url)
                                }
                            }
                            .font(.subheadline)
                        }
                    }

                    Divider()

                    // MARK: Privacy Policy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.headline)
                        Text("FunCalendar does not collect, store, or transmit any personal data. All settings are saved locally on your device only and are never sent to any server. In-app purchases are processed entirely by Apple.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Link("Read full Privacy Policy", destination: URL(string: privacyURL)!)
                            .font(.subheadline)
                    }

                    Divider()

                    // MARK: Terms of Use
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms of Use")
                            .font(.headline)
                        Text("By downloading and using FunCalendar, you agree to Apple's standard Licensed Application End User License Agreement (EULA).")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Link("View Apple's Standard EULA", destination: URL(string: appleEULAURL)!)
                            .font(.subheadline)
                    }

                    Divider()

                    // MARK: In-App Purchases
                    VStack(alignment: .leading, spacing: 8) {
                        Text("In-App Purchases")
                            .font(.headline)
                        Text("""
FunCalendar offers a one-time Lifetime License ($2.99) that unlocks widget customization. This is a non-consumable purchase — pay once and it is yours permanently, with no subscriptions or recurring charges.

If you have previously purchased the Lifetime License on this Apple ID, you can restore it at no charge using the "Restore Purchase" option in the app.

All billing is handled by Apple through the App Store. Purchases are subject to Apple's media purchase terms.
""")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // MARK: Copyright
                    Text("© \(Calendar.current.component(.year, from: Date())) Nicolas Schimmelpfennig. All rights reserved.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)

                    // MARK: Developer Override
                    if store.developerMode {
                        Button {
                            store.disableDeveloperOverride()
                        } label: {
                            Label("Disable Developer Override", systemImage: "lock.open")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        Button {
                            passwordInput = ""
                            showPasswordPrompt = true
                        } label: {
                            Label("Developer Override", systemImage: "lock")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
            .alert("Developer Override", isPresented: $showPasswordPrompt) {
                SecureField("Password", text: $passwordInput)
                Button("Unlock") {
                    if passwordInput == "OVERWRITE" {
                        store.overridePurchase()
                    } else {
                        showWrongPassword = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter the override password to bypass the paywall.")
            }
            .alert("Incorrect password", isPresented: $showWrongPassword) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

#Preview {
    AboutView(store: StoreViewModel())
}
