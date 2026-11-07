import Observation

/// Holds UI state that must survive the expanded view being torn down and
/// recreated on every hover (DynamicNotchKit rebuilds its content view each
/// time), e.g. which tab was selected — otherwise it always resets to Todo.
@Observable
final class NotchUIState {
    var tab: NotchTab = .home
}
