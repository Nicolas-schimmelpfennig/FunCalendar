//
//  AboutView.swift
//  FunCalendar
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("About")
                    .font(.largeTitle.bold())
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("A note from me")
                        .font(.headline)
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy")
                        .font(.headline)
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam ac ante vel arcu porttitor tincidunt. Phasellus imperdiet, nulla et dictum interdum, nisi lorem egestas odio.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms of Use")
                        .font(.headline)
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum. Donec in efficitur leo, in commodo orci. Sed ac ipsum non augue faucibus interdum.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("In-App Purchases")
                        .font(.headline)
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur pretium tincidunt lacus. Nulla gravida orci a odio et, a semper ligula rhoncus.")
                        .font(.body)
                        .foregroundStyle(.secondary)
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
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
            }
        }
        }
    }
}

#Preview {
    AboutView()
}
