import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

struct AdPlaceholderView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.brandPrimary20)
            .frame(height: 120)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.3.offgrid")
                        .font(.title2)
                        .foregroundColor(.brandPrimary60)
                    Text("広告スペース")
                        .font(AppFont.footnote)
                        .foregroundColor(.brandPrimary60)
                }
            )
            .accessibilityLabel("広告プレースホルダ")
            .accessibilityHint("将来的に広告が表示される予定のスペースです")
    }
}

#if canImport(GoogleMobileAds)
struct AdMobNativeAdView: UIViewRepresentable {
    let adUnitId: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.backgroundColor = .clear
        nativeAdView.clipsToBounds = true
        
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill  // Fitではなく、Fillで枠内に収める
        mediaView.clipsToBounds = true
        nativeAdView.mediaView = mediaView
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)  // 小さめのフォント
        headlineLabel.numberOfLines = 1
        nativeAdView.headlineView = headlineLabel
        
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 12)  // 小さいフォント
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 1  // 1行に制限
        nativeAdView.bodyView = bodyLabel
        
        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        ctaButton.backgroundColor = UIColor.systemBlue
        ctaButton.tintColor = .white
        ctaButton.layer.cornerRadius = 6
        nativeAdView.callToActionView = ctaButton
        
        // 任意アセット: アイコンと広告主名
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 6
        iconImageView.clipsToBounds = true
        nativeAdView.iconView = iconImageView

        let advertiserLabel = UILabel()
        advertiserLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        advertiserLabel.textColor = .secondaryLabel
        advertiserLabel.numberOfLines = 1
        nativeAdView.advertiserView = advertiserLabel

        // 必須要素のみ：メディア、見出し、CTAボタンのみ
        let stack = UIStackView(arrangedSubviews: [mediaView, headlineLabel, ctaButton])
        stack.axis = .vertical
        stack.spacing = 2  // 最小限の間隔
        stack.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(stack)
        
        // アイコンと広告主名は非表示（スペース節約）
        iconImageView.isHidden = true
        advertiserLabel.isHidden = true
        bodyLabel.isHidden = true
        
        // AdChoices バッジをビュー内に固定
        let adChoicesView = AdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.adChoicesView = adChoicesView
        nativeAdView.addSubview(adChoicesView)

        NSLayoutConstraint.activate([
            // MediaViewは固定高さ120ptに制限（巨大画像を防ぐ）
            mediaView.heightAnchor.constraint(equalToConstant: 120),
            mediaView.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: stack.trailingAnchor),  // 幅を親スタックに合わせる
            ctaButton.heightAnchor.constraint(equalToConstant: 32),  // CTAボタン高さ
            stack.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 2),
            stack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -2),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -2),
            adChoicesView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 2),
            adChoicesView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -2),
            adChoicesView.widthAnchor.constraint(equalToConstant: 15),
            adChoicesView.heightAnchor.constraint(equalToConstant: 15)
        ])

        // デバッグ用境界可視化
        #if DEBUG
        nativeAdView.layer.borderWidth = 2
        nativeAdView.layer.borderColor = UIColor.red.cgColor
        mediaView.layer.borderWidth = 1
        mediaView.layer.borderColor = UIColor.blue.cgColor
        #endif
        
        context.coordinator.nativeAdView = nativeAdView
        context.coordinator.mediaView = mediaView
        loadAd(context: context)
        return nativeAdView
    }
    
    func updateUIView(_ uiView: NativeAdView, context: Context) {
        // フレーム更新時にレイアウトを強制
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }

    // SwiftUIに適切なサイズを返す
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: NativeAdView, context: Context) -> CGSize {
        // 提案された幅を使用（フル幅）
        let width = proposal.width ?? UIScreen.main.bounds.width - 40
        // 高さは固定180pt
        return CGSize(width: width, height: 180)
    }
    
    private func loadAd(context: Context) {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }
        
        let adLoader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        context.coordinator.onReceiveAd = { [weak coordinator = context.coordinator] nativeAd in
            guard let view = coordinator?.nativeAdView else { return }
            (view.headlineView as? UILabel)?.text = nativeAd.headline
            view.mediaView?.mediaContent = nativeAd.mediaContent
            (view.bodyView as? UILabel)?.text = nativeAd.body
            (view.iconView as? UIImageView)?.image = nativeAd.icon?.image
            (view.advertiserView as? UILabel)?.text = nativeAd.advertiser
            (view.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
            view.callToActionView?.isUserInteractionEnabled = false
            view.nativeAd = nativeAd

            // メディアは固定高さ120ptのため、アスペクト比調整は不要
            // scaleAspectFillで画像を枠内に収める
        }
        adLoader.delegate = context.coordinator
        context.coordinator.adLoader = adLoader
        adLoader.load(Request())
    }
    
    class Coordinator: NSObject, NativeAdLoaderDelegate {
        var adLoader: AdLoader?
        var nativeAdView: NativeAdView?
        var mediaView: MediaView?
        var mediaAspectConstraint: NSLayoutConstraint?
        var onReceiveAd: ((NativeAd) -> Void)?
        
        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("❌ Failed to load native ad: \(error)")
            #endif
        }
        
        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            onReceiveAd?(nativeAd)
        }
    }
}
#endif

struct NativeAdContainerView: View {
    let adUnitId: String
    
    var body: some View {
        Group {
            if FeatureFlags.adsEnabled {
                #if canImport(GoogleMobileAds)
                // UIViewControllerRepresentableを使用
                AdMobNativeAdViewController(adUnitId: adUnitId)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "EDF3FF"), Color(hex: "E6EEFF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                #else
                AdPlaceholderView()
                #endif
            } else {
                AdPlaceholderView()
            }
        }
    }
}


