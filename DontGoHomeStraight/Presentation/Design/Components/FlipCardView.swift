import SwiftUI
import UIKit

// MARK: - Flip Card

/// 裏向きのカードをタップすると3D回転で表面が現れる汎用コンポーネント
struct FlipCardView<Front: View, Back: View>: View {
    let isFlipped: Bool
    let onFlip: () -> Void
    @ViewBuilder let front: () -> Front
    @ViewBuilder let back: () -> Back

    var body: some View {
        ZStack {
            back()
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )

            front()
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
        }
        .onTapGesture {
            guard !isFlipped else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                onFlip()
            }
        }
    }
}

// MARK: - Detour Card Back

/// ジャンル選択画面で使う「裏向きカード」のデザイン
struct DetourCardBack: View {
    let index: Int
    @State private var shimmer = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient.appHeroGradient)

            // うっすら光る装飾
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.0), Color.white.opacity(0.18), Color.white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(shimmer ? 1.0 : 0.2)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: shimmer)

            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                .padding(8)

            VStack(spacing: 10) {
                Text("？")
                    .font(.system(size: 52, weight: .heavy))
                    .foregroundColor(.white)

                Text("寄り道カード \(index)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 11))
                    Text("タップしてめくる")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .shadow(color: Color.appPurpleStart.opacity(0.35), radius: 18, x: 0, y: 10)
        .onAppear {
            shimmer = true
        }
    }
}

// MARK: - Preview

#Preview {
    struct FlipDemo: View {
        @State private var flipped = false

        var body: some View {
            FlipCardView(
                isFlipped: flipped,
                onFlip: { flipped = true },
                front: {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(height: 210)
                        .overlay(Text("表面"))
                },
                back: {
                    DetourCardBack(index: 1)
                }
            )
            .padding()
        }
    }
    return FlipDemo()
}
