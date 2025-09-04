import SwiftUI
import UIKit
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

#if canImport(GoogleMobileAds)
// UIViewControllerRepresentableを使用して幅を正しく伝達
struct AdMobNativeAdViewController: UIViewControllerRepresentable {
    let adUnitId: String
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let nativeAdView = NativeAdView()
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.backgroundColor = .clear
        
        // MediaView
        let mediaView = MediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        nativeAdView.mediaView = mediaView
        
        // 見出し
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 14, weight: .medium)
        headlineLabel.numberOfLines = 1
        nativeAdView.headlineView = headlineLabel
        
        // CTAボタン
        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        ctaButton.backgroundColor = .systemBlue
        ctaButton.tintColor = .white
        ctaButton.layer.cornerRadius = 6
        nativeAdView.callToActionView = ctaButton
        
        // スタック（シンプルに3要素のみ）
        let stack = UIStackView(arrangedSubviews: [mediaView, headlineLabel, ctaButton])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(stack)
        
        // AdChoicesバッジ
        let adChoicesView = AdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.adChoicesView = adChoicesView
        nativeAdView.addSubview(adChoicesView)
        
        // ViewControllerのviewに追加
        viewController.view.addSubview(nativeAdView)
        
        // 制約設定 - ViewControllerのviewに対して四辺を固定
        NSLayoutConstraint.activate([
            // NativeAdViewを親ビューに完全に固定
            nativeAdView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            nativeAdView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            
            // MediaView
            mediaView.heightAnchor.constraint(equalToConstant: 120),
            
            // CTAボタン
            ctaButton.heightAnchor.constraint(equalToConstant: 32),
            
            // スタック
            stack.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -4),
            
            // AdChoices
            adChoicesView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 4),
            adChoicesView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -4),
            adChoicesView.widthAnchor.constraint(equalToConstant: 15),
            adChoicesView.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        // デバッグ用
        #if DEBUG
        nativeAdView.layer.borderWidth = 2
        nativeAdView.layer.borderColor = UIColor.red.cgColor
        #endif
        
        // 広告をロード
        context.coordinator.nativeAdView = nativeAdView
        loadAd(context: context)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 更新時に何もしない
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
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
        
        context.coordinator.onReceiveAd = { nativeAd in
            guard let view = context.coordinator.nativeAdView else { return }
            (view.headlineView as? UILabel)?.text = nativeAd.headline
            view.mediaView?.mediaContent = nativeAd.mediaContent
            (view.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
            view.callToActionView?.isUserInteractionEnabled = false
            view.nativeAd = nativeAd
        }
        
        adLoader.delegate = context.coordinator
        context.coordinator.adLoader = adLoader
        adLoader.load(Request())
    }
    
    class Coordinator: NSObject, NativeAdLoaderDelegate {
        var adLoader: AdLoader?
        var nativeAdView: NativeAdView?
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
