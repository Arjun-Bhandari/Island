import SwiftUI

enum NotchTab: String, CaseIterable {
    case home = "Home"
    case todo = "Todo"
    case scripts = "Scripts"
    case monitor = "Monitor"
    case cleanup = "Cleanup"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: "house"
        case .todo: "checklist"
        case .scripts: "terminal"
        case .monitor: "cpu"
        case .cleanup: "trash"
        case .settings: "gearshape"
        }
    }
}

/// Dropdown shown while hovering. Home is a dashboard; the rest are one
/// module each. Tab bar sits on top, pill-style.
struct NotchExpandedView: View {
    let todoStore: TodoStore
    let scriptStore: ScriptStore
    let systemStats: SystemStats
    let cleanupScanner: CleanupScanner
    let uiState: NotchUIState

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            Divider().background(.white.opacity(0.1))

            Group {
                switch uiState.tab {
                case .home: HomeView(todoStore: todoStore, cleanupScanner: cleanupScanner, systemStats: systemStats)
                case .todo: TodoView(store: todoStore)
                case .scripts: ScriptRunnerView(store: scriptStore)
                case .monitor: MonitorView(stats: systemStats, cleanupScanner: cleanupScanner)
                case .cleanup: CleanupView(scanner: cleanupScanner)
                case .settings: SettingsView()
                }
            }
            // Fixed height so switching tabs (or an empty list) never shrinks
            // the panel — a shrink can land the mouse outside the window and
            // trigger an unwanted hover-exit/collapse.
            .frame(height: 230, alignment: .top)
        }
        .frame(width: 520)
    }

    /// Inactive tabs are icon-only circles; the active one expands into a
    /// labeled pill, matching the reference design.
    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(NotchTab.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        uiState.tab = item
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 12, weight: .medium))
                        if uiState.tab == item {
                            Text(item.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .fixedSize()
                        }
                    }
                    .foregroundStyle(uiState.tab == item ? .black : .secondary)
                    .padding(.horizontal, uiState.tab == item ? 12 : 9)
                    .padding(.vertical, 7)
                    .background(
                        uiState.tab == item ? Color.white : Color.white.opacity(0.08),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
    }
}
