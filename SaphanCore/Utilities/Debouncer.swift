import Foundation

public class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue

    public init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    public func debounce(action: @escaping () -> Void) {
        workItem?.cancel()

        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem

        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }

    public func debounceAsync(action: @escaping () async -> Void) {
        debounce {
            Task {
                await action()
            }
        }
    }

    public func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

public class Throttler {
    private let interval: TimeInterval
    private var lastExecutionTime: Date?
    private let queue: DispatchQueue

    public init(interval: TimeInterval, queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }

    public func throttle(action: @escaping () -> Void) {
        let now = Date()

        if let lastTime = lastExecutionTime {
            let timeSinceLastExecution = now.timeIntervalSince(lastTime)
            if timeSinceLastExecution < interval {
                return
            }
        }

        lastExecutionTime = now
        queue.async {
            action()
        }
    }

    public func reset() {
        lastExecutionTime = nil
    }
}
