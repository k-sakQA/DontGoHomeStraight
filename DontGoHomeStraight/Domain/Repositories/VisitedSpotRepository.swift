import Foundation

/// 寄り道図鑑（訪問済みスポット）の永続化を担うリポジトリ
protocol VisitedSpotRepository {
    /// 全訪問スポットを取得（訪問日時の新しい順）
    func getAll() -> [VisitedSpot]

    /// 到着したスポットを記録する。既訪問なら訪問回数を加算して返す
    @discardableResult
    func record(place: Place, mood: Mood?) -> VisitedSpot

    /// 図鑑を全消去する
    func clear()
}
