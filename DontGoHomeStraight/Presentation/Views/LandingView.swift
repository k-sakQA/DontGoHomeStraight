import SwiftUI

struct LandingView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showLogo = false
    @State private var showButtons = false
    
    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 48) {
                Spacer()
                
                // ロゴセクション
                logoSection
                
                Spacer()
                
                // ボタンセクション
                if showButtons {
                    buttonSection
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    @ViewBuilder
    private var logoSection: some View {
        VStack(spacing: 24) {
            // アプリロゴ
            LogoView(size: 120)
                .scaleEffect(showLogo ? 1.0 : 0.5)
                .opacity(showLogo ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showLogo)
            
            // アプリ名
            VStack(spacing: 8) {
                Text("まっすぐ帰りたくない")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "212529"))
                
                Text("どこか寄り道したい！")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "6C757D"))
            }
            .opacity(showLogo ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: showLogo)
        }
    }
    
    @ViewBuilder
    private var buttonSection: some View {
        VStack(spacing: 16) {
            // 寄り道するボタン
            Button(action: {
                viewModel.currentScreen = .home
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("寄り道する")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            // キャッシュ削除ボタン
            Button(action: {
                Task {
                    await viewModel.clearRecommendationCache()
                }
            }) {
                Text("キャッシュ削除")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(viewModel.isLoading)
            
            // 説明文
            Text("過去に提案した場所のキャッシュを削除します")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "6C757D"))
                .multilineTextAlignment(.center)

            // プライバシーポリシーへのリンク（App Store 対応）
            if let policyURL = URL(string: "https://generated-lupin-fb3.notion.site/26ae4385342e80acb80afd7bd0313257?source=copy_link") {
                Link(destination: policyURL) {
                    Text("プライバシーポリシー")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "3A7DFF"))
                        .underline()
                        .frame(maxWidth: .infinity)
                }
                .accessibilityLabel("プライバシーポリシーへのリンク")
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showLogo = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showButtons = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LandingView(viewModel: AppViewModel.preview)
}
