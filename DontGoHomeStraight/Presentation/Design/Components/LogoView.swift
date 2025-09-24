import SwiftUI

// MARK: - LogoView

/// アプリロゴを表示するビュー
/// - ライトモード: logo_blue.pdf を使用
/// - ダークモード: logo_white.pdf を使用  
/// - サイズ可変対応
struct LogoView: View {
    
    // MARK: - Properties
    
    /// ロゴのサイズ (デフォルト: 96pt)
    let size: CGFloat
    
    /// 表示する見た目（自動/ライト/ダーク）
    enum Appearance {
        case auto
        case light
        case dark
    }
    let appearance: Appearance
    
    /// 現在のカラースキーム（ライト/ダーク）
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    
    /// LogoViewを初期化
    /// - Parameters:
    ///   - size: ロゴのサイズ (デフォルト: 96pt)
    ///   - appearance: 見た目（自動/ライト/ダーク）。ライト指定で常にblue、ダーク指定でwhite
    init(size: CGFloat = 96, appearance: Appearance = .auto) {
        self.size = size
        self.appearance = appearance
    }
    
    // MARK: - Body
    
    var body: some View {
        let image = Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityLabel("アプリロゴ")
            .accessibilityHint("DontGoHomeStraightアプリのロゴ")
        switch appearance {
        case .auto:
            image
        case .light:
            image.environment(\.colorScheme, .light)
        case .dark:
            image.environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - LogoView Variants

extension LogoView {
    
    /// 小サイズのロゴ (48pt)
    static var small: LogoView {
        LogoView(size: 48)
    }
    
    /// 中サイズのロゴ (72pt) 
    static var medium: LogoView {
        LogoView(size: 72)
    }
    
    /// 大サイズのロゴ (96pt) - デフォルト
    static var large: LogoView {
        LogoView(size: 96)
    }
    
    /// 特大サイズのロゴ (128pt)
    static var extraLarge: LogoView {
        LogoView(size: 128)
    }
}

// MARK: - Preview

#if DEBUG
struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            // サイズバリエーションのプレビュー
            VStack(spacing: 16) {
                Text("ロゴサイズバリエーション")
                    .headingStyle()
                    .foregroundColor(.brandPrimary)
                
                HStack(spacing: 20) {
                    VStack {
                        LogoView.small
                        Text("Small (48pt)")
                            .footnoteStyle()
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        LogoView.medium
                        Text("Medium (72pt)")
                            .footnoteStyle()
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        LogoView.large
                        Text("Large (96pt)")
                            .footnoteStyle()
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // カラースキーム対応のプレビュー
            VStack(spacing: 16) {
                Text("カラースキーム対応")
                    .headingStyle()
                    .foregroundColor(.brandPrimary)
                
                HStack(spacing: 40) {
                    VStack {
                        LogoView()
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .preferredColorScheme(.light)
                        
                        Text("Light Mode")
                            .footnoteStyle()
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        LogoView()
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .preferredColorScheme(.dark)
                        
                        Text("Dark Mode")
                            .footnoteStyle()
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif