import SwiftUI
import CoreLocation

struct TransportModeSelectionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedMode: TransportMode?
    
    var body: some View {
        VStack(spacing: 24) {
            // ヘッダー情報
            destinationInfoSection
            
            // 移動手段選択グリッド
            transportModeGrid
            
            Spacer()
            
            // ナビゲーションボタン
            navigationButton
        }
        .padding()
        .navigationTitle("移動手段を選択")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var destinationInfoSection: some View {
        if let destination = viewModel.destination {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text("目的地")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Text(destination.name)
                        .font(.body)
                        .lineLimit(2)
                    Spacer()
                }
            }
            .padding()
            .background(Color.appSurfaceAlt)
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var transportModeGrid: some View {
        VStack(spacing: 16) {
            Text("どの方法で移動しますか？")
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(TransportMode.allCases, id: \.self) { mode in
                    TransportModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMode = mode
                            }
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var navigationButton: some View {
        Button(action: {
            guard let selectedMode = selectedMode else { return }
            viewModel.setTransportMode(selectedMode)
            viewModel.navigateToMoodSelection()
        }) {
            HStack {
                Image(systemName: "arrow.right")
                Text("次へ")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedMode != nil ? Color.appPrimary : Color.gray)
            .cornerRadius(12)
        }
        .disabled(selectedMode == nil)
    }
}

// MARK: - Transport Mode Card

struct TransportModeCard: View {
    let mode: TransportMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // アイコン
                Image(systemName: mode.icon)
                    .font(.system(size: 40))
                    .foregroundColor(iconColor)
                
                // 名前
                Text(mode.displayName)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                
                // 説明
                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.appPrimary.opacity(0.1)
        } else {
            return Color.appSurfaceAlt
        }
    }
    
    private var borderColor: Color {
        isSelected ? .appPrimary : .gray.opacity(0.3)
    }
    
    private var iconColor: Color {
        isSelected ? .appPrimary : .primary
    }
    
    private var textColor: Color {
        isSelected ? .appPrimary : .primary
    }
}

// MARK: - TransportMode Extensions

extension TransportMode {
    var description: String {
        switch self {
        case .walking:
            return "健康的で環境に優しい"
        case .driving:
            return "快適で自由度が高い"
        case .transit:
            return "経済的で効率的"
        case .cycling:
            return "エコで運動にもなる"
        }
    }
    
    var emoji: String {
        switch self {
        case .walking: return "🚶‍♂️"
        case .driving: return "🚗"
        case .transit: return "🚇"
        case .cycling: return "🚴‍♂️"
        }
    }
    
    var estimatedSpeedKmh: Double {
        switch self {
        case .walking: return 4.0
        case .driving: return 30.0
        case .transit: return 20.0
        case .cycling: return 15.0
        }
    }
}

// MARK: - Enhanced Transport Mode View

struct EnhancedTransportModeCard: View {
    let mode: TransportMode
    let isSelected: Bool
    let estimatedTime: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // アイコンとエモジ
                HStack {
                    Text(mode.emoji)
                        .font(.title)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appPrimary)
                            .font(.title2)
                    }
                }
                
                // メインコンテンツ
                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .appPrimary : .primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if let estimatedTime = estimatedTime {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("約\(estimatedTime)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.appPrimary.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        isSelected ? .appPrimary : .gray.opacity(0.3)
    }
}

// MARK: - Transport Mode Selection with Time Estimates

struct TransportModeSelectionWithEstimatesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedMode: TransportMode?
    @State private var estimatedTimes: [TransportMode: String] = [:]
    
    var body: some View {
        VStack(spacing: 24) {
            destinationInfoSection
            
            VStack(spacing: 16) {
                Text("どの方法で移動しますか？")
                    .font(.title3)
                    .fontWeight(.medium)
                
                VStack(spacing: 12) {
                    ForEach(TransportMode.allCases, id: \.self) { mode in
                        EnhancedTransportModeCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            estimatedTime: estimatedTimes[mode],
                            onTap: {
                                selectedMode = mode
                            }
                        )
                    }
                }
            }
            
            Spacer()
            
            navigationButton
        }
        .padding()
        .navigationTitle("移動手段を選択")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateEstimatedTimes()
        }
    }
    
    @ViewBuilder
    private var destinationInfoSection: some View {
        if let destination = viewModel.destination {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text("目的地")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Text(destination.name)
                        .font(.body)
                        .lineLimit(2)
                    Spacer()
                }
                
                if let distance = calculateDistance() {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(.secondary)
                        Text("距離: \(distance)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.appSurfaceAlt)
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var navigationButton: some View {
        Button(action: {
            guard let selectedMode = selectedMode else { return }
            viewModel.setTransportMode(selectedMode)
            viewModel.navigateToMoodSelection()
        }) {
            HStack {
                Image(systemName: "arrow.right")
                Text("次へ")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedMode != nil ? Color.appPrimary : Color.gray)
            .cornerRadius(12)
        }
        .disabled(selectedMode == nil)
    }
    
    private func calculateDistance() -> String? {
        guard let currentLocation = viewModel.currentLocation,
              let destination = viewModel.destination else { return nil }
        
        let distance = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            .distance(from: CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude))
        
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func calculateEstimatedTimes() {
        guard let currentLocation = viewModel.currentLocation,
              let destination = viewModel.destination else { return }
        
        let distance = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            .distance(from: CLLocation(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude))
        
        let distanceKm = distance / 1000.0
        
        for mode in TransportMode.allCases {
            let timeHours = distanceKm / mode.estimatedSpeedKmh
            let timeMinutes = Int(timeHours * 60)
            
            if timeMinutes < 60 {
                estimatedTimes[mode] = "\(timeMinutes)分"
            } else {
                let hours = timeMinutes / 60
                let minutes = timeMinutes % 60
                estimatedTimes[mode] = "\(hours)時間\(minutes)分"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SwiftUI.NavigationView {
        TransportModeSelectionView(viewModel: AppViewModel.preview)
    }
}

#Preview("With Estimates") {
    SwiftUI.NavigationView {
        TransportModeSelectionWithEstimatesView(viewModel: AppViewModel.preview)
    }
}