import Foundation
import ActivityKit

/// ミステリー寄り道のLive Activity属性
/// 注意: アプリ本体の Infrastructure/LiveActivity/DetourActivityAttributes.swift と
/// 定義を完全に一致させること（構造が一致しないとLive Activityが表示されない）
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
