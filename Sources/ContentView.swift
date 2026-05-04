import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("totalStars") private var totalStars = 0
    @AppStorage("isSetupDone") private var isSetupDone = false
    @AppStorage("appLanguage") private var appLanguage = "ja"  // 言語変更でUI更新

    @State private var showParentSettings = false

    var body: some View {
        if !isSetupDone {
            SetupView(isSetupDone: $isSetupDone)
        } else {
            VStack(spacing: 0) {
                // ヘッダー: 星 + 設定
                HStack {
                    // 設定ボタン: 長押しで開く（子供が誤タップしないように）
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(8)
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.8) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showParentSettings = true
                        }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("⭐").font(.system(size: 16))
                        Text("\(totalStars)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.star)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(AppColors.star.opacity(0.15)))
                }
                .padding(.horizontal)
                .padding(.top, 4)

                // コンテンツ
                Group {
                    switch selectedTab {
                    case 0: QuestBoardView(totalStars: $totalStars)
                    case 1: ScheduleView()
                    case 2: StatsView()
                    case 3: ShopView(totalStars: $totalStars)
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // タブバー
                HStack {
                    tabButton("🗡️", L10n.tabQuest, 0)
                    tabButton("📅", L10n.tabSchedule, 1)
                    tabButton("📊", L10n.tabStats, 2)
                    tabButton("🎁", L10n.tabShop, 3)
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(AppColors.cardBackground)
            }
            .background(AppColors.background)
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $showParentSettings) {
                ParentSettingsView()
            }
        }
    }

    private func tabButton(_ icon: String, _ label: String, _ index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 2) {
                Text(icon).font(.system(size: 22))
                Text(label).font(.system(size: 10, weight: selectedTab == index ? .bold : .regular))
            }
            .foregroundColor(selectedTab == index ? AppColors.accent : AppColors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(selectedTab == index ? [.isSelected] : [])
    }
}
