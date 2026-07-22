import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// ミステリー寄り道のLive Activity属性
/// 注意: DontGoHomeStraightWidget/DetourActivityAttributes.swift と定義を一致させること
struct DetourActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 経由地までの残り距離（メートル）。nilは計測前
        var distanceMeters: Double?
        /// ロック画面に表示するステータス文言
        var statusMessage: String
    }

    /// ジャンルカテゴリの絵文字（🍽️ / 🏛️）
    var genreEmoji: String
    /// ジャンルカテゴリ名（グルメ / その他）
    var genreCategoryName: String
    /// AIが生成したヒント
    var hint: String?
    /// 最終目的地の名前
    var destinationName: String
}
#endif
