import ComposableArchitecture

public extension Reducer {
  /// Prints messages describing all received local actions and local state mutations.
  ///
  /// Printing is done in any build configurations.
  ///
  /// - Parameters:
  ///   - prefix: A string with which to prefix all debug messages.
  ///   - toLocalState: A function that filters state to be printed.
  ///   - toLocalAction: A case path that filters actions that are printed.
  ///   - toDebugEnvironment: A function that transforms an environment into a debug environment by
  ///     describing a print function and a queue to print from. Defaults to a function that ignores
  ///     the environment and returns a default ``DebugEnvironment`` that uses Swift's `print`
  ///     function and a background queue.
  /// - Returns: A reducer that prints debug messages for all received actions.
  func print<LocalState, LocalAction>(
    _ prefix: String = "",
    state toLocalState: @escaping (State) -> LocalState,
    action toLocalAction: CasePath<Action, LocalAction>,
    environment toDebugEnvironment: @escaping (Environment) -> DebugEnvironment = { _ in
      DebugEnvironment()
    }
  ) -> Reducer {
    return .init { state, action, environment in
      let previousState = toLocalState(state)
      let effects = self.run(&state, action, environment)
      guard let localAction = toLocalAction.extract(from: action) else { return effects }
      let nextState = toLocalState(state)
      let debugEnvironment = toDebugEnvironment(environment)
      return .merge(
        .fireAndForget {
          debugEnvironment.queue.async {
            var actionOutput = ""
            customDump(localAction, to: &actionOutput, indent: 2)
            let stateOutput =
              LocalState.self == Void.self
              ? ""
              : diff(previousState, nextState).map { "\($0)\n" } ?? "  (No state changes)\n"
            debugEnvironment.printer(
                  """
                  \(prefix.isEmpty ? "" : "\(prefix): ")received action:
                  \(actionOutput)
                  \(stateOutput)
                  """
            )
          }
        },
        effects
      )
    }
  }
}

