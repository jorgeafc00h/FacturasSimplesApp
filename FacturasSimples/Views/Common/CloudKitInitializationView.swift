//
//  CloudKitSyncStatusView.swift
//  FacturasSimples
//
//  Created by GitHub Copilot on 6/14/25.
//

import SwiftUI

struct CloudKitInitializationView: View {
    @StateObject private var syncManager = CloudKitSyncManager.shared
    @State private var showDetails = false
    let onComplete: () -> Void
    
    var body: some View {
        
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 18/255, green: 31/255, blue: 61/255),
                    Color(red: 25/255, green: 42/255, blue: 86/255),
                    Color(red: 31/255, green: 54/255, blue: 112/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles background effect
            backgroundParticles()
            
            VStack(spacing: 30) {
                // App Logo with glow effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                }
                
                VStack(spacing: 16) {
                    Text("Facturas Simples")
                        .font(.custom("Bradley Hand", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Text("Configurando tu información...")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Sync Status Section with glass morphism
                VStack(spacing: 20) {
                    // Progress Indicator
                    if syncManager.isSyncing {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                    } else {
                        Image(systemName: syncStatusIcon)
                            .font(.system(size: 40))
                            .foregroundColor(syncStatusColor)
                    }
                    
                    // Status Message
                    Text(syncManager.statusMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    // Detailed Message
                    if !syncManager.syncMessage.isEmpty {
                        Text(syncManager.syncMessage)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                
                Spacer()
                
                // Action Buttons with onboarding-style black capsule buttons
                VStack(spacing: 16) {
                    // Continue Button (shown when sync is complete or failed)
                    if !syncManager.isSyncing {
                        Button("Continuar") {
                            onComplete()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .frame(width: UIScreen.main.bounds.width * 0.4)
                        .background {
                            Capsule().fill(.black)
                        }
                    }
                    
                    // Retry Button (shown on error)
                    if case .error = syncManager.syncStatus {
                        Button("Reintentar Sincronización") {
                            Task {
                                await syncManager.forceSyncRefresh()
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .frame(width: UIScreen.main.bounds.width * 0.6)
                        .background {
                            Capsule().fill(.black)
                        }
                    }
                    
                    // Skip Button (always available)
                    Button("Omitir por Ahora") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, 12)
                    .frame(width: UIScreen.main.bounds.width * 0.35)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal, 20)
            }
            .padding()
        }
        .task {
            await syncManager.performInitialSync()
        }
    }
    
    private var syncStatusIcon: String {
        switch syncManager.syncStatus {
        case .unknown, .checking, .syncing:
            return "icloud.and.arrow.down"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .noAccount:
            return "icloud.slash"
        case .notAvailable:
            return "wifi.slash"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncManager.syncStatus {
        case .unknown, .checking, .syncing:
            return .white
        case .completed:
            return .green.opacity(0.9)
        case .error:
            return .red.opacity(0.9)
        case .noAccount, .notAvailable:
            return .orange.opacity(0.9)
        }
    }
    
    private func backgroundParticles() -> some View {
        ZStack {
            ForEach(0..<25, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.05...0.15)))
                    .frame(width: CGFloat.random(in: 3...12))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 15...35))
                            .repeatForever(autoreverses: false)
                            .delay(Double.random(in: 0...5)),
                        value: index
                    )
                    .onAppear {
                        // Create continuous floating animation
                        withAnimation(
                            Animation.linear(duration: Double.random(in: 20...40))
                                .repeatForever(autoreverses: true)
                        ) {
                            // Random movement
                        }
                    }
            }
            
            // Add some larger, slower moving particles for depth
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: CGFloat.random(in: 20...40))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 40...80))
                            .repeatForever(autoreverses: false),
                        value: index
                    )
            }
        }
    }
}

#Preview {
    CloudKitInitializationView {
        print("Sync complete")
    }
}
