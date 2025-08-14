import SwiftUI

struct MoodSelectionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedActivityType: ActivityType?
    @State private var selectedVibeType: VibeType?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // ヘッダー情報
                headerSection
                
                // アクティビティタイプ選択
                activityTypeSection
                
                // バイブタイプ選択
                vibeTypeSection
                
                // 選択された気分の表示
                if let mood = currentMood {
                    selectedMoodDisplay(mood)
                }
                
                Spacer(minLength: 20)
                
                // ナビゲーションボタン（システム提案）
                navigationButton
                
                // AIで提案する（明示ボタン）
                aiSuggestionButton
            }
            .padding()
        }
        .navigationTitle("今の気分は？")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("✨")
                .font(.system(size: 60))
            
            Text("あなたの今の気分を教えてください")
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text("AIがあなたの気分に合った\n素敵な寄り道先を提案します")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var activityTypeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("アクティビティタイプ")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("どちらか1つ選択")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                ForEach(ActivityType.allCases, id: \.self) { activityType in
                    ActivityTypeCard(
                        activityType: activityType,
                        isSelected: selectedActivityType == activityType,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedActivityType = activityType
                            }
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var vibeTypeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("バイブタイプ")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("どれか1つ選択")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(VibeType.allCases, id: \.self) { vibeType in
                    VibeTypeCard(
                        vibeType: vibeType,
                        isSelected: selectedVibeType == vibeType,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedVibeType = vibeType
                            }
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func selectedMoodDisplay(_ mood: Mood) -> some View {
        VStack(spacing: 12) {
            Text("選択された気分")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Text(mood.activityType.emoji)
                    .font(.title2)
                Text(mood.activityType.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("+")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(mood.vibeType.emoji)
                    .font(.title2)
                Text(mood.vibeType.displayName)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Text(mood.detailedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var navigationButton: some View {
        Button(action: {
            guard let mood = currentMood else { return }
            viewModel.setMood(mood)
            viewModel.navigateToGenreSelection()
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("寄り道を提案する")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(currentMood != nil ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(currentMood == nil)
    }

    @ViewBuilder
    private var aiSuggestionButton: some View {
        Button(action: {
            guard let mood = currentMood else { return }
            viewModel.setMood(mood)
            viewModel.navigateToGenreSelectionAI()
        }) {
            HStack {
                Image(systemName: "brain.head.profile")
                Text("AIで提案する")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .disabled(currentMood == nil)
    }
    
    private var currentMood: Mood? {
        guard let activityType = selectedActivityType,
              let vibeType = selectedVibeType else {
            return nil
        }
        return Mood(activityType: activityType, vibeType: vibeType)
    }
}

// MARK: - Activity Type Card

struct ActivityTypeCard: View {
    let activityType: ActivityType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(activityType.emoji)
                    .font(.system(size: 32))
                
                Text(activityType.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Text(activityType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        isSelected ? .blue : .gray.opacity(0.3)
    }
}

// MARK: - Vibe Type Card

struct VibeTypeCard: View {
    let vibeType: VibeType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(vibeType.emoji)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vibeType.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .blue : .primary)
                    
                    Text(vibeType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        isSelected ? .blue : .gray.opacity(0.3)
    }
}

// MARK: - Extensions for Descriptions

extension ActivityType {
    var description: String {
        switch self {
        case .indoor:
            return "建物の中で過ごしたい"
        case .outdoor:
            return "外の空気を感じたい"
        }
    }
}

extension VibeType {
    var description: String {
        switch self {
        case .jazzy:
            return "大人っぽく落ち着いた雰囲気"
        case .discovery:
            return "新しい何かを見つけたい"
        case .exciting:
            return "ワクワクする体験がしたい"
        }
    }
}

extension Mood {
    var detailedDescription: String {
        switch (activityType, vibeType) {
        case (.indoor, .jazzy):
            return "落ち着いた室内で、ジャズが似合うような洗練された雰囲気の場所がおすすめです"
        case (.indoor, .discovery):
            return "室内で新しい発見や学びがある場所を探します"
        case (.indoor, .exciting):
            return "室内でワクワクするような刺激的な体験ができる場所をご提案します"
        case (.outdoor, .jazzy):
            return "屋外で、ジャズが似合うような洗練された雰囲気の場所がおすすめです"
        case (.outdoor, .discovery):
            return "屋外で新しい発見や驚きがある場所を探します"
        case (.outdoor, .exciting):
            return "屋外でワクワクするような活動的な体験ができる場所をご提案します"
        }
    }
}

// MARK: - Interactive Mood Preview

struct MoodPreviewCard: View {
    let mood: Mood
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack {
                    Text(mood.activityType.emoji)
                        .font(.largeTitle)
                    Text(mood.activityType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("×")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack {
                    Text(mood.vibeType.emoji)
                        .font(.largeTitle)
                    Text(mood.vibeType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Text(mood.detailedDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    SwiftUI.NavigationView {
        MoodSelectionView(viewModel: AppViewModel.preview)
    }
}

#Preview("Selected Mood") {
    VStack {
        MoodPreviewCard(mood: Mood(activityType: .outdoor, vibeType: .exciting))
        MoodPreviewCard(mood: Mood(activityType: .indoor, vibeType: .jazzy))
    }
    .padding()
}