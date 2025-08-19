import SwiftUI

// MARK: - App Typography System

/// アプリ全体で使用するタイポグラフィシステム
struct AppFont {
    
    // MARK: - Font Styles
    
    /// 見出し用フォント
    /// - 使用場面: セクションタイトル、重要なタイトルなど
    /// - スタイル: .title3.weight(.semibold)
    static let heading: Font = .title3.weight(.semibold)
    
    /// 本文用フォント  
    /// - 使用場面: 通常のテキスト、説明文など
    /// - スタイル: .body
    static let body: Font = .body
    
    /// 副文用フォント
    /// - 使用場面: キャプション、補足情報など  
    /// - スタイル: .footnote
    static let footnote: Font = .footnote
    
    // MARK: - Button Typography
    
    /// ボタンテキスト用フォント
    /// - 使用場面: CTAボタン、アクションボタンなど
    /// - スタイル: .headline (太字でアクセントを強調)
    static let button: Font = .headline
    
    // MARK: - Navigation Typography
    
    /// ナビゲーション用フォント
    /// - 使用場面: ナビゲーションタイトルなど
    /// - スタイル: .title2.weight(.bold)
    static let navigationTitle: Font = .title2.weight(.bold)
}

// MARK: - Text Extensions for Typography

extension Text {
    /// 見出しスタイルを適用
    func headingStyle() -> some View {
        self.font(AppFont.heading)
    }
    
    /// 本文スタイルを適用
    func bodyStyle() -> some View {
        self.font(AppFont.body)
    }
    
    /// 副文スタイルを適用
    func footnoteStyle() -> some View {
        self.font(AppFont.footnote)
    }
    
    /// ボタンテキストスタイルを適用
    func buttonStyle() -> some View {
        self.font(AppFont.button)
    }
    
    /// ナビゲーションタイトルスタイルを適用
    func navigationTitleStyle() -> some View {
        self.font(AppFont.navigationTitle)
    }
}

// MARK: - Typography Preview Helper

#if DEBUG
struct AppFontPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("見出し - Heading")
                .headingStyle()
                .foregroundColor(.brandPrimary)
            
            Text("本文テキスト - Body text for regular content and descriptions.")
                .bodyStyle()
                .foregroundColor(.primary)
            
            Text("副文・キャプション - Footnote for additional information")
                .footnoteStyle()
                .foregroundColor(.secondary)
            
            Text("ボタンテキスト - Button")
                .buttonStyle()
                .foregroundColor(.white)
                .padding()
                .background(Color.brandPrimary)
                .cornerRadius(12)
            
            Text("ナビゲーションタイトル - Navigation")
                .navigationTitleStyle()
                .foregroundColor(.brandPrimary)
        }
        .padding()
    }
}

#Preview {
    AppFontPreview()
}
#endif