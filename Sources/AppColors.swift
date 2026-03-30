import SwiftUI

enum AppColors {
    // 背景: 柔らかいクリーム（子供に優しい、目が疲れない）
    static let background = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let cardBackground = Color.white
    static let cardShadow = Color.black.opacity(0.06)

    // テキスト
    static let textPrimary = Color(red: 0.20, green: 0.20, blue: 0.25)
    static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.60)

    // アクセント（楽しい、元気な色）
    static let accent = Color(red: 1.0, green: 0.60, blue: 0.20)       // オレンジ
    static let star = Color(red: 1.0, green: 0.82, blue: 0.20)         // ゴールド
    static let success = Color(red: 0.30, green: 0.78, blue: 0.45)     // グリーン
    static let bonus = Color(red: 0.95, green: 0.40, blue: 0.55)       // ピンク

    // 時間帯
    static let morning = Color(red: 1.0, green: 0.85, blue: 0.50)      // 朝: 暖かい黄色
    static let afternoon = Color(red: 0.55, green: 0.80, blue: 1.0)    // 昼: 空色
    static let evening = Color(red: 0.60, green: 0.50, blue: 0.85)     // 夜: 紫

    // クエスト完了度
    static let progressEmpty = Color(red: 0.90, green: 0.90, blue: 0.92)
    static let progressFill = Color(red: 0.30, green: 0.78, blue: 0.45)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.cardShadow, radius: 4, y: 2)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}
