import SwiftUI

// MARK: - Helper Functions
private func safePercentage(from value: Double) -> Int {
    let percentage = value * 100
    
    // Check for invalid values (infinite or NaN)
    if percentage.isInfinite || percentage.isNaN {
        return 0
    }
    
    // Clamp the value between 0 and 100
    let clampedPercentage = max(0, min(100, percentage))
    
    return Int(clampedPercentage.rounded())
}

private func safeProgress(from value: Double) -> Double {
    // Check for invalid values (infinite or NaN)
    if value.isInfinite || value.isNaN {
        return 0.0
    }
    
    // Clamp the value between 0 and 1
    return max(0.0, min(1.0, value))
}

// MARK: - Document Progress View
struct DocumentProgressView: View {
    let title: String
    let progress: Double
    let status: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            ProgressView(value: safeProgress(from: progress), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(y: 2.0)
            
            HStack {
                Text("\(safePercentage(from: progress))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Enhanced Progress View
struct EnhancedProgressView: View {
    let title: String
    let progress: Double
    let icon: String
    let isActive: Bool
    var showAsOverall: Bool = false
    
    @State private var animationProgress: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(showAsOverall ? .green : .accentColor)
                    .frame(width: 24)
                    .font(.title2)
                
                Text(title)
                    .font(showAsOverall ? .title2 : .headline)
                    .fontWeight(showAsOverall ? .bold : .medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isActive {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            VStack(spacing: 8) {
                ProgressView(value: safeProgress(from: animationProgress), total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: showAsOverall ? .green : .accentColor))
                    .scaleEffect(y: showAsOverall ? 3.0 : 2.5)
                
                HStack {
                    Text("\(safePercentage(from: animationProgress))%")
                        .font(showAsOverall ? .title3 : .callout)
                        .fontWeight(showAsOverall ? .bold : .medium)
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                    
                    if showAsOverall && animationProgress >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
            }
        }
        .padding(showAsOverall ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(showAsOverall ? 0.15 : 0.1), radius: showAsOverall ? 8 : 4, x: 0, y: showAsOverall ? 4 : 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animationProgress = safeProgress(from: progress)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationProgress = safeProgress(from: newValue)
            }
        }
    }
}

// MARK: - Preview
#Preview("Document Progress") {
    VStack(spacing: 16) {
        DocumentProgressView(
            title: "Facturas",
            progress: 0.75,
            status: "Procesando...",
            icon: "doc.text"
        )
        
        EnhancedProgressView(
            title: "Progreso General",
            progress: 0.5,
            icon: "chart.bar.fill",
            isActive: true,
            showAsOverall: true
        )
    }
    .padding()
}
