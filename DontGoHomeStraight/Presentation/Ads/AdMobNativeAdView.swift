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
    
    func makeUIView(context: Context) -> GADNativeAdView {
        let nativeAdView = GADNativeAdView()
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        
        let mediaView = GADMediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.mediaView = mediaView
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        headlineLabel.numberOfLines = 2
        nativeAdView.headlineView = headlineLabel
        
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        nativeAdView.bodyView = bodyLabel
        
        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        ctaButton.backgroundColor = UIColor.systemBlue
        ctaButton.tintColor = .white
        ctaButton.layer.cornerRadius = 8
        nativeAdView.callToActionView = ctaButton
        
        let stack = UIStackView(arrangedSubviews: [mediaView, headlineLabel, bodyLabel, ctaButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            mediaView.heightAnchor.constraint(equalToConstant: 90),
            ctaButton.heightAnchor.constraint(equalToConstant: 36),
            stack.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -12)
        ])
        
        context.coordinator.nativeAdView = nativeAdView
        loadAd(context: context)
        return nativeAdView
    }
    
    func updateUIView(_ uiView: GADNativeAdView, context: Context) {}
    
    private func loadAd(context: Context) {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }
        
        let adLoader = GADAdLoader(
            adUnitID: adUnitId,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        context.coordinator.onReceiveAd = { [weak context] nativeAd in
            guard let view = context?.coordinator.nativeAdView else { return }
            (view.headlineView as? UILabel)?.text = nativeAd.headline
            view.mediaView?.mediaContent = nativeAd.mediaContent
            (view.bodyView as? UILabel)?.text = nativeAd.body
            (view.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
            view.callToActionView?.isUserInteractionEnabled = false
            view.nativeAd = nativeAd
        }
        adLoader.delegate = context.coordinator
        context.coordinator.adLoader = adLoader
        adLoader.load(GADRequest())
    }
    
    class Coordinator: NSObject, GADNativeAdLoaderDelegate {
        var adLoader: GADAdLoader?
        var nativeAdView: GADNativeAdView?
        var onReceiveAd: ((GADNativeAd) -> Void)?
        
        func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("❌ Failed to load native ad: \(error)")
            #endif
        }
        
        func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
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
                AdMobNativeAdView(adUnitId: adUnitId)
                    .frame(height: 150)
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


