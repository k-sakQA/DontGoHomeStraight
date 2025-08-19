import SwiftUI

// MARK: - BrandButton

/// ブランドスタイルのボタンコンポーネント
/// - 角丸16pt、高さ52pt、シャドウ付き
/// - ローディング状態と無効状態をサポート
struct BrandButton: View {
    
    // MARK: - Properties
    
    /// ボタンのタイトル
    let title: String
    
    /// ボタンが押された時のアクション
    let action: () -> Void
    
    /// ローディング中かどうか
    let isLoading: Bool
    
    /// ボタンが有効かどうか  
    let isEnabled: Bool
    
    /// ボタンスタイル（プライマリ/セカンダリ）
    let style: ButtonStyle
    
    // MARK: - Button Styles
    
    enum ButtonStyle {
        case primary
        case secondary
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .brandPrimary
            case .secondary: return .brandPrimary20
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .brandPrimary
            }
        }
        
        var disabledBackgroundColor: Color {
            return Color.gray.opacity(0.3)
        }
        
        var disabledForegroundColor: Color {
            return Color.gray
        }
    }
    
    // MARK: - Initialization
    
    /// BrandButtonを初期化
    /// - Parameters:
    ///   - title: ボタンのタイトル
    ///   - style: ボタンスタイル（デフォルト: .primary）
    ///   - isLoading: ローディング中かどうか（デフォルト: false）
    ///   - isEnabled: ボタンが有効かどうか（デフォルト: true）
    ///   - action: ボタンが押された時のアクション
    init(
        title: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    // MARK: - Computed Properties
    
    /// ボタンが実際にタップ可能かどうか
    private var isInteractable: Bool {
        return isEnabled && !isLoading
    }
    
    /// 現在の背景色
    private var currentBackgroundColor: Color {
        if isInteractable {
            return style.backgroundColor
        } else {
            return style.disabledBackgroundColor
        }
    }
    
    /// 現在の前景色
    private var currentForegroundColor: Color {
        if isInteractable {
            return style.foregroundColor
        } else {
            return style.disabledForegroundColor
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if isInteractable {
                action()
            }
        }) {
            HStack(spacing: 8) {
                // ローディングインディケータ
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: currentForegroundColor))
                }
                
                // ボタンタイトル
                Text(title)
                    .font(AppFont.button)
                    .foregroundColor(currentForegroundColor)
                    .opacity(isLoading ? 0.7 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52) // 設計書で指定された高さ
            .background(currentBackgroundColor)
            .cornerRadius(16) // 設計書で指定された角丸
            .shadow(
                color: .black.opacity(0.12), // 設計書で指定されたシャドウ
                radius: 12,
                x: 0,
                y: 4
            )
            .scaleEffect(isInteractable ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.2), value: isInteractable)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .disabled(!isInteractable)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "読み込み中です" : "ボタンです")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - BrandButton Convenience Initializers

extension BrandButton {
    
    /// プライマリボタンを作成
    static func primary(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> BrandButton {
        BrandButton(
            title: title,
            style: .primary,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }
    
    /// セカンダリボタンを作成
    static func secondary(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> BrandButton {
        BrandButton(
            title: title,
            style: .secondary,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }
}

// MARK: - Preview

#if DEBUG
struct BrandButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            Text("BrandButton コンポーネント")
                .headingStyle()
                .foregroundColor(.brandPrimary)
            
            // プライマリボタンバリエーション
            VStack(spacing: 16) {
                Text("Primary Buttons")
                    .bodyStyle()
                    .foregroundColor(.secondary)
                
                BrandButton.primary(title: "通常状態", action: {})
                
                BrandButton.primary(title: "ローディング中", isLoading: true, action: {})
                
                BrandButton.primary(title: "無効状態", isEnabled: false, action: {})
            }
            
            // セカンダリボタンバリエーション
            VStack(spacing: 16) {
                Text("Secondary Buttons")
                    .bodyStyle()
                    .foregroundColor(.secondary)
                
                BrandButton.secondary(title: "通常状態", action: {})
                
                BrandButton.secondary(title: "ローディング中", isLoading: true, action: {})
                
                BrandButton.secondary(title: "無効状態", isEnabled: false, action: {})
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Color(UIColor.systemBackground))
    }
}
#endif