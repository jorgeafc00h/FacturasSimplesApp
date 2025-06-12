//
//  CloudKitSyncStatusView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/10/25.
//

import SwiftUI
import SwiftData
import CloudKit
import CoreData

struct CloudKitSyncStatusView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var companyStorageManager: CompanyStorageManager
    @State private var syncStatus: CloudKitSyncStatus = .unknown
    @State private var lastSyncDate: Date?
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: syncStatusIcon)
                .foregroundColor(syncStatusColor)
                .font(.caption)
            
            if syncStatus == .syncing {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .onAppear {
            setupCloudKitMonitoring()
            checkInitialSyncStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
            // Only update sync status if current company uses CloudKit
            if let currentCompany = companyStorageManager.currentCompany,
               currentCompany.shouldSyncToCloudKit {
                updateSyncStatus(.synced)
            }
        }
        .onChange(of: companyStorageManager.currentCompany) { oldCompany, newCompany in
            // Update sync status when company changes
            checkInitialSyncStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .companyDataUpdated)) { _ in
            // Update sync status when company data changes (e.g., name, settings)
            checkInitialSyncStatus()
        }
    }
    
    private var syncStatusIcon: String {
        // If current company is test account, show local icon
        if let currentCompany = companyStorageManager.currentCompany,
           currentCompany.isTestAccount {
            return "internaldrive"
        }
        
        switch syncStatus {
        case .unknown:
            return "icloud.circle"
        case .notAvailable:
            return "icloud.slash"
        case .syncing:
            return "icloud.and.arrow.up"
        case .synced:
            return "icloud.and.arrow.down"
        case .error:
            return "icloud.slash.fill"
        }
    }
    
    private var syncStatusColor: Color {
        // If current company is test account, show gray (local storage)
        if let currentCompany = companyStorageManager.currentCompany,
           currentCompany.isTestAccount {
            return .gray
        }
        
        switch syncStatus {
        case .unknown:
            return .gray
        case .notAvailable:
            return .orange
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .error:
            return .red
        }
    }
    
    private func setupCloudKitMonitoring() {
        // Monitor when data changes locally (indicating sync might start)
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { _ in
            if syncStatus != .syncing {
                updateSyncStatus(.syncing)
                
                // Reset to synced after a delay (since we can't directly monitor CloudKit sync completion)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if syncStatus == .syncing {
                        updateSyncStatus(.synced)
                    }
                }
            }
        }
    }
    
    private func checkInitialSyncStatus() {
        // If current company is test account, don't check CloudKit
        if let currentCompany = companyStorageManager.currentCompany,
           currentCompany.isTestAccount {
            updateSyncStatus(.notAvailable) // Local storage, no CloudKit
            return
        }
        
        Task {
            let (isAvailable, error) = await CloudKitConfiguration.shared.checkAccountStatus()
            
            await MainActor.run {
                if let error = error {
                    print("CloudKit error: \(error)")
                    updateSyncStatus(.error)
                } else if isAvailable {
                    updateSyncStatus(.synced)
                } else {
                    updateSyncStatus(.notAvailable)
                }
            }
        }
    }
    
    private func updateSyncStatus(_ newStatus: CloudKitSyncStatus) {
        withAnimation(.easeInOut(duration: 0.3)) {
            syncStatus = newStatus
            if newStatus == .synced {
                lastSyncDate = Date()
            }
        }
    }
}

#Preview {
    CloudKitSyncStatusView()
}
