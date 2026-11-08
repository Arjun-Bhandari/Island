import SwiftUI
import KeyboardShortcuts

private enum OnboardingStep: Int, CaseIterable {
    case welcome, features, shortcuts, setup, ready
}

struct OnboardingView: View {
    let finish: () -> Void
    @State private var step: OnboardingStep = .welcome
    @State private var forward = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case .welcome: WelcomeStep()
                case .features: FeaturesStep()
                case .shortcuts: ShortcutsStep()
                case .setup: SetupStep()
                case .ready: ReadyStep()
                }
            }
            .id(step)
            .transition(pageTransition)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 40)
            .padding(.top, 44)

            footer
        }
        .frame(width: 640, height: 480)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }

    private var pageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .offset(x: forward ? 40 : -40).combined(with: .opacity),
            removal: .offset(x: forward ? -40 : 40).combined(with: .opacity)
        )
    }

    private var footer: some View {
        HStack {
            if step == .welcome {
                Button("Skip", action: finish)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut(.cancelAction)
            } else {
                OnboardingButton(title: "Back") { go(by: -1) }
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.self) { s in
                    Capsule()
                        .fill(s == step ? Color.white : Color.white.opacity(0.2))
                        .frame(width: s == step ? 18 : 6, height: 6)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")

            Spacer()

            if step == .ready {
                OnboardingButton(title: "Open Island", primary: true, action: finish)
                    .keyboardShortcut(.defaultAction)
            } else {
                OnboardingButton(title: "Continue", primary: true) { go(by: 1) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .overlay(alignment: .top) { Divider().background(.white.opacity(0.1)) }
    }

    private func go(by delta: Int) {
        guard let next = OnboardingStep(rawValue: step.rawValue + delta) else { return }
        forward = delta > 0
        withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) { step = next }
    }
}

// MARK: - Steps

private struct WelcomeStep: View {
    @State private var installError: String?

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("Welcome to Island")
                .font(.system(size: 28, weight: .semibold))
            Text("Your MacBook's notch, put to work. Todos, scripts, a system monitor and dev cleanup — one hover or one shortcut away.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            if AppInstaller.needsInstall {
                installCard.padding(.top, 10)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var installCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 20))
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("Move Island to Applications")
                    .font(.system(size: 13, weight: .semibold))
                Text(installError ?? "Needed for Launch at Login. Island will restart from there.")
                    .font(.system(size: 11))
                    .foregroundStyle(installError == nil ? Color.secondary : Color.red)
            }
            Spacer()
            OnboardingButton(title: "Move", primary: true) {
                do {
                    try AppInstaller.moveToApplications()
                } catch {
                    installError = "Couldn't move it: \(error.localizedDescription) Drag Island.app into Applications instead."
                }
            }
        }
        .padding(14)
        .frame(maxWidth: 460)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct FeaturesStep: View {
    private let features: [(icon: String, title: String, detail: String)] = [
        (NotchTab.home.icon, "Home", "Date, calendar, today's todos and quick stats at a glance."),
        (NotchTab.todo.icon, "Todo", "Capture a task in a second. It's there after restarts."),
        (NotchTab.scripts.icon, "Scripts", "Save commands you run often. Run, stop and see status."),
        (NotchTab.monitor.icon, "Monitor", "Live CPU, memory and storage usage."),
        (NotchTab.cleanup.icon, "Cleanup", "Find node_modules, build caches and DerivedData. Moves to Trash."),
        ("keyboard", "Keyboard-first", "Every tab and action has a global shortcut you can change."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepHeading(title: "Everything in one hover", subtitle: "Six tabs live inside the notch.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(features, id: \.title) { feature in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title).font(.system(size: 13, weight: .semibold))
                            Text(feature.detail)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ShortcutsStep: View {
    private let jumps: [(String, KeyboardShortcuts.Name)] = [
        ("Home", .goHome), ("Todo", .goTodo), ("Scripts", .goScripts),
        ("Monitor", .goMonitor), ("Cleanup", .goCleanup), ("Settings", .goSettings),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepHeading(title: "Drive it from the keyboard", subtitle: "Click a shortcut and press a new combo to change it.")
            VStack(spacing: 10) {
                recorderRow("Open or close the notch", .toggleNotch)
                recorderRow("Quick-add a todo", .quickAddTodo)
                recorderRow("Open Scripts", .quickScripts)
            }
            .padding(14)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text("Jump straight to a tab")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(jumps, id: \.0) { label, name in
                        VStack(spacing: 4) {
                            KeyCap(text: name.shortcut?.description ?? "—")
                            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            Text("Esc closes the notch · ⌘Q quits Island · Each script can get its own shortcut too.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func recorderRow(_ label: String, _ name: KeyboardShortcuts.Name) -> some View {
        HStack {
            Text(label).font(.system(size: 13))
            Spacer()
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}

private struct SetupStep: View {
    @State private var loginItem = LoginItem()
    @State private var launchAtLogin = false
    @AppStorage(NotchController.keyboardOnlyKey) private var keyboardOnly = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepHeading(title: "Make it yours", subtitle: "You can change these any time in the Settings tab.")
            VStack(spacing: 0) {
                toggleRow(
                    icon: "power",
                    title: "Launch at login",
                    detail: AppInstaller.needsInstall
                        ? "Move Island to Applications first (previous step)."
                        : "Island is always there after a restart.",
                    isOn: $launchAtLogin
                )
                .disabled(AppInstaller.needsInstall)
                .onChange(of: launchAtLogin) { _, newValue in loginItem.setEnabled(newValue) }
                Divider().background(.white.opacity(0.1)).padding(.vertical, 10)
                toggleRow(
                    icon: "keyboard",
                    title: "Keyboard only",
                    detail: "Hovering won't open the notch — use the shortcut instead.",
                    isOn: $keyboardOnly
                )
            }
            .padding(14)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { launchAtLogin = loginItem.isEnabled }
    }

    private func toggleRow(icon: String, title: String, detail: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold))
                Text(detail).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(title, isOn: isOn).labelsHidden().toggleStyle(.switch)
        }
    }
}

private struct ReadyStep: View {
    @AppStorage(NotchController.keyboardOnlyKey) private var keyboardOnly = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.05))
                    .frame(width: 320, height: 120)
                UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12)
                    .fill(.black)
                    .overlay(
                        UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12)
                            .stroke(.white.opacity(pulse ? 0.6 : 0.15), lineWidth: 1)
                    )
                    .frame(width: 130, height: 30)
                Image(systemName: keyboardOnly ? "keyboard" : "cursorarrow")
                    .font(.system(size: 20))
                    .offset(x: 10, y: pulse ? 34 : 64)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
            }

            Text("You're all set")
                .font(.system(size: 24, weight: .semibold))
            Text(instructions)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxHeight: .infinity)
    }

    private var instructions: String {
        let toggle = KeyboardShortcuts.Name.toggleNotch.shortcut?.description ?? "your toggle shortcut"
        return keyboardOnly
            ? "Press \(toggle) anywhere to open Island. Quit any time from Settings or with ⌘Q."
            : "Rest your pointer on the notch for a moment, or press \(toggle). Quit any time from Settings or with ⌘Q."
    }
}

// MARK: - Shared bits

private struct StepHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 22, weight: .semibold))
            Text(subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }
}

private struct KeyCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.12)))
    }
}

private struct OnboardingButton: View {
    let title: String
    var primary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(primary ? .black : .white)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(primary ? Color.white : Color.white.opacity(0.1), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
