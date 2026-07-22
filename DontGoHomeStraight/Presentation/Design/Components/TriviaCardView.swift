import SwiftUI

/// 「今日はまっすぐ帰りましょう🎵」のときに表示する豆知識カード
struct TriviaCardView: View {
    @State private var trivia: String = DetourTrivia.random()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("💡")
                    .font(.system(size: 18))
                Text("帰り道の豆知識")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "0D1B3A"))
                Spacer()
            }

            Text(trivia)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "4B5563"))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .id(trivia)
                .transition(.opacity)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    trivia = DetourTrivia.random(excluding: trivia)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                    Text("別の豆知識を見る")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color(hex: "3A7DFF"))
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF9E6"), Color(hex: "FFF3CC")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "FFC107").opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    TriviaCardView()
        .padding()
}
