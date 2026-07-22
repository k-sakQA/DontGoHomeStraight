import ActivityKit
import WidgetKit
import SwiftUI

/// ミステリー寄り道のLive Activity
/// ロック画面とDynamic Islandに「??? まで あと○○m」を表示する
struct DetourLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DetourActivityAttributes.self) { context in
            // ロック画面・通知バナー
            LockScreenDetourView(context: context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.11, blue: 0.23))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.genreEmoji)
                        .font(.system(size: 32))
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(distanceText(context.state.distanceMeters))
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("？？？へ寄り道中")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.statusMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            } compactLeading: {
                Text("🕵️")
            } compactTrailing: {
                Text(distanceText(context.state.distanceMeters))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } minimal: {
                Text("🕵️")
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenDetourView: View {
    let context: ActivityViewContext<DetourActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(context.attributes.genreEmoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text("？？？？？？ へ寄り道中")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)

                    Text("ジャンル: \(context.attributes.genreCategoryName)｜スポット名は到着まで秘密")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("あと")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.65))
                    Text(distanceText(context.state.distanceMeters))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
            }

            if let hint = context.attributes.hint, !hint.isEmpty {
                Text("ヒント: \(hint)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Text(context.state.statusMessage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.83, blue: 0.35))
        }
        .padding(16)
    }
}

// MARK: - Helpers

private func distanceText(_ meters: Double?) -> String {
    guard let meters = meters else { return "計測中" }
    if meters < 1000 {
        return String(format: "%.0fm", meters)
    }
    return String(format: "%.1fkm", meters / 1000)
}
