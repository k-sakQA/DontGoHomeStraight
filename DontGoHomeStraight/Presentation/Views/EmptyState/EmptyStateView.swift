import SwiftUI

// MARK: - EmptyStateView

/// 候補が0件の時に表示する空状態ビュー
/// - ロゴ、メッセージ、広告プレースホルダ、戻るボタンを含む
/// - NavigationStack対応（path.removeAll()）と通常のdismiss()をサポート
struct EmptyStateView: View {
    
    // MARK: - Properties
    
    /// NavigationStackのパス（存在する場合）
    var navigationPath: Binding<[AnyHashable]>?
    
    /// タイトルテキスト
    let titleText: String
    
    /// サブタイトルテキスト
    let subtitleText: String
    
    /// ボタンのタイトル
    let buttonTitle: String
    
    /// 広告プレースホルダを表示するかどうか
    let showAdPlaceholder: Bool
    
    /// 戻る処理で使用するdismissアクション
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    /// EmptyStateViewを初期化
    /// - Parameters:
    ///   - navigationPath: NavigationStackのパス（オプション）
    ///   - titleText: タイトルテキスト
    ///   - subtitleText: サブタイトルテキスト  
    ///   - buttonTitle: ボタンのタイトル
    ///   - showAdPlaceholder: 広告プレースホルダを表示するかどうか
    init(
        navigationPath: Binding<[AnyHashable]>? = nil,
        titleText: String = "候補が見つかりませんでした",
        subtitleText: String = "条件を変更して再度お試しください",
        buttonTitle: String = "トップに戻る",
        showAdPlaceholder: Bool = true
    ) {
        self.navigationPath = navigationPath
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.buttonTitle = buttonTitle
        self.showAdPlaceholder = showAdPlaceholder
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                
                // ロゴセクション
                logoSection
                
                // メッセージセクション  
                messageSection
                
                // 広告プレースホルダ（オプション）
                if showAdPlaceholder {
                    adPlaceholderSection
                }
                
                // 戻るボタン
                backButton
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarBackButtonHidden(true)
        .accessibilityLabel("空の状態画面")
        .accessibilityHint("候補が見つからない状態です")
    }
    
    // MARK: - View Components
    
    /// ロゴセクション
    @ViewBuilder
    private var logoSection: some View {
        VStack(spacing: 16) {
            LogoView(size: 80)
                .opacity(0.6)
            
            Text("DontGoHomeStraight")
                .font(AppFont.heading)
                .foregroundColor(.brandPrimary60)
        }
    }
    
    /// メッセージセクション
    @ViewBuilder  
    private var messageSection: some View {
        VStack(spacing: 12) {
            Text(titleText)
                .font(AppFont.heading)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(subtitleText)
                .font(AppFont.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    /// 広告プレースホルダセクション
    @ViewBuilder
    private var adPlaceholderSection: some View {
        VStack(spacing: 12) {
            Text("広告")
                .font(AppFont.footnote)
                .foregroundColor(.secondary)
            
            NativeAdContainerView(adUnitId: Environment.adMobNativeAdUnitId)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
        }
    }
    
    /// 戻るボタン
    @ViewBuilder
    private var backButton: some View {
        BrandButton.primary(
            title: buttonTitle,
            action: handleBackAction
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Actions
    
    /// 戻る処理
    /// NavigationStackがある場合は path.removeAll()、ない場合は dismiss()
    private func handleBackAction() {
        if let navigationPath = navigationPath {
            // NavigationStack使用時はパスをクリア
            navigationPath.wrappedValue.removeAll()
        } else {
            // 通常のナビゲーション時はdismiss
            dismiss()
        }
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    
    /// 寄り道候補なし用の空状態ビュー
    static func noDetourCandidates(
        navigationPath: Binding<[AnyHashable]>? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            navigationPath: navigationPath,
            titleText: "寄り道候補が見つかりませんでした",
            subtitleText: "条件を変更して再度お試しいただくか、\n別の目的地を設定してください",
            buttonTitle: "トップに戻る",
            showAdPlaceholder: true
        )
    }
    
    /// 検索結果なし用の空状態ビュー
    static func noSearchResults(
        navigationPath: Binding<[AnyHashable]>? = nil
    ) -> EmptyStateView {
        EmptyStateView(
            navigationPath: navigationPath,
            titleText: "検索結果が見つかりませんでした",
            subtitleText: "検索条件を変更して再度お試しください",
            buttonTitle: "検索に戻る",
            showAdPlaceholder: false
        )
    }
}

// MARK: - Preview

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // デフォルトの空状態ビュー
            SwiftUI.NavigationView {
                EmptyStateView()
                    .navigationTitle("Empty State")
            }
            .previewDisplayName("Default")
            
            // 寄り道候補なし
            SwiftUI.NavigationView {
                EmptyStateView.noDetourCandidates()
                    .navigationTitle("No Detour")
            }
            .previewDisplayName("No Detour Candidates")
            
            // 検索結果なし
            SwiftUI.NavigationView {
                EmptyStateView.noSearchResults()
                    .navigationTitle("No Results")
            }
            .previewDisplayName("No Search Results")
            
            // ダークモード
            SwiftUI.NavigationView {
                EmptyStateView()
                    .navigationTitle("Dark Mode")
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif