//
//  CloudKitResetView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI
import CloudKit
import SwiftData

struct CloudKitResetView: View {
    @StateObject private var resetManager = CloudKitResetManager.shared
    @State private var showingConfirmation = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                VStack(spacing: 16) {
                    Text("Nuclear Reset")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("This will completely delete ALL data from both your device and iCloud")
                        .font(.headline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("This will delete:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "building.2")
                            Text("All companies (production and test)")
                        }
                        HStack {
                            Image(systemName: "person.2")
                            Text("All customers")
                        }
                        HStack {
                            Image(systemName: "doc.text")
                            Text("All invoices")
                        }
                        HStack {
                            Image(systemName: "cube.box")
                            Text("All products")
                        }
                        HStack {
                            Image(systemName: "icloud")
                            Text("All iCloud/CloudKit data")
                        }
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if resetManager.isResetting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text(resetManager.resetProgress)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        Button("🗑️ DELETE EVERYTHING") {
                            showingConfirmation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.red)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reset CloudKit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog(
            "Are you absolutely sure?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("YES, DELETE EVERYTHING", role: .destructive) {
                performReset()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted from both your device and iCloud.")
        }
        .alert("Reset Successful", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("All data has been successfully deleted. You can now start fresh.")
        }
        .alert("Reset Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func performReset() {
        Task {
            do {
                try await resetManager.performNuclearReset()
                await MainActor.run {
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    CloudKitResetView()
}
