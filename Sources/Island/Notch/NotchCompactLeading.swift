import SwiftUI

/// Shown on the left side of the notch pill when idle.
struct NotchCompactLeading: View {
    let store: TodoStore
    let scriptStore: ScriptStore
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checklist")
                .font(.system(size: 12, weight: .medium))
            if store.remainingCount > 0 {
                Text("\(store.remainingCount)")
                    .font(.system(size: 11, weight: .semibold))
            }

            if scriptStore.hasRunningScript {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
                    .opacity(pulse ? 0.35 : 1)
                    .scaleEffect(pulse ? 0.85 : 1)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                    }
            }
        }
        .foregroundStyle(.white)
    }
}
