import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// ミステリー寄り道のLive Activity（ロック画面・Dynamic Island表示）を管理する
/// ロック画面のUIは DontGoHomeStraightWidget ターゲット側で描画される
/// （docs/LIVE_ACTIVITY_SETUP.md 参照。ターゲット未追加でもアプリ本体の動作には影響しない）
@MainActor
final class DetourLiveActivityManager {
    static let shared = DetourLiveActivityManager()

    private init() {}

    #if canImport(ActivityKit)
    private var activity: Activity<DetourActivityAttributes>?
    #endif

    /// ナビ開始時にLive Activityを開始する
    func start(genre: Genre, destinationName: String) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            #if DEBUG
            print("ℹ️ Live Activityが無効のため開始をスキップ")
            #endif
            return
        }

        // 前回分が残っていれば終了してから開始
        endImmediately()

        let attributes = DetourActivityAttributes(
            genreEmoji: genre.category.emoji,
            genreCategoryName: genre.category.displayName,
            hint: genre.hint,
            destinationName: destinationName
        )
        let initialState = DetourActivityAttributes.ContentState(
            distanceMeters: nil,
            statusMessage: "ミステリースポットへ向かっています…"
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            #if DEBUG
            print("✅ Live Activityを開始しました")
            #endif
        } catch {
            #if DEBUG
            print("❌ Live Activityの開始に失敗: \(error)")
            #endif
        }
        #endif
    }

    /// 残り距離を更新する（距離に応じて文言も変化）
    func updateDistance(_ meters: Double) {
        #if canImport(ActivityKit)
        guard let activity = activity else { return }

        let message: String
        switch meters {
        case ..<150:
            message = "もうすぐ種明かし…！"
        case ..<400:
            message = "だいぶ近づいてきました"
        case ..<1000:
            message = "いい調子！このまま進みましょう"
        default:
            message = "ミステリースポットへ向かっています…"
        }

        let state = DetourActivityAttributes.ContentState(
            distanceMeters: meters,
            statusMessage: message
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
        #endif
    }

    /// 到着時: スポット名を種明かしして終了（しばらくロック画面に残す）
    func endWithReveal(placeName: String) {
        #if canImport(ActivityKit)
        guard let activity = activity else { return }
        self.activity = nil

        let finalState = DetourActivityAttributes.ContentState(
            distanceMeters: 0,
            statusMessage: "ここは「\(placeName)」でした！"
        )
        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(Date().addingTimeInterval(30 * 60))
            )
        }
        #endif
    }

    /// 経路案内の中断時などに即座に終了する
    func endImmediately() {
        #if canImport(ActivityKit)
        guard let activity = activity else { return }
        self.activity = nil

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        #endif
    }
}
