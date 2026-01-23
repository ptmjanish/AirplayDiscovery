//
//  Reachability.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation
import Network

final class Reachability {

    static let shared = Reachability()

    enum ConnectionType: String {
        case wifi, cellular, wired, other, none
    }

    struct Status: Equatable, CustomStringConvertible {
        let isReachable: Bool
        let isExpensive: Bool
        let isConstrained: Bool
        let connectionType: ConnectionType

        static let unreachable = Status(
            isReachable: false,
            isExpensive: false,
            isConstrained: false,
            connectionType: .none
        )

        var description: String {
            "Status(reachable=\(isReachable), type=\(connectionType.rawValue), expensive=\(isExpensive), constrained=\(isConstrained))"
        }
    }

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "Reachability.Monitor.Queue")

    private(set) var currentStatus: Status = .unreachable {
        didSet {
            if oldValue != currentStatus {
                notifyObservers(currentStatus)
            }
        }
    }

    private var observers: [(Status) -> Void] = []

    private var hasInitialUpdate = false
    private var initialContinuations: [CheckedContinuation<Status, Never>] = []

    private init() {
        monitor = NWPathMonitor()
        start()
    }

    deinit {
        monitor.cancel()
    }

    var isReachable: Bool { currentStatus.isReachable }

    func observe(_ observer: @escaping (Status) -> Void) {
        observers.append(observer)
        observer(currentStatus)
    }

    /// Wait until the first real NWPathMonitor update arrives (or timeout).
    func waitForInitialStatus(timeout: TimeInterval = 0.8) async -> Status {
        if hasInitialUpdate { return currentStatus }

        return await withTaskGroup(of: Status.self) { group in
            // Task A: Wait for first update
            group.addTask { [weak self] in
                guard let self else { return .unreachable }
                return await withCheckedContinuation { cont in
                    self.initialContinuations.append(cont)
                }
            }

            // Task B: Timeout fallback
            group.addTask {
                let ns = UInt64(timeout * 1_000_000_000)
                try? await Task.sleep(nanoseconds: ns)
                return self.currentStatus // whatever we have by then
            }

            let first = await group.next() ?? currentStatus
            group.cancelAll()
            return first
        }
    }

    // MARK: - Private

    private func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newStatus = self.makeStatus(from: path)

            DispatchQueue.main.async {
                self.currentStatus = newStatus
                print("Reachability update:", newStatus)

                if !self.hasInitialUpdate {
                    self.hasInitialUpdate = true
                    let continuations = self.initialContinuations
                    self.initialContinuations.removeAll()
                    continuations.forEach { $0.resume(returning: newStatus) }
                }
            }
        }

        monitor.start(queue: queue)
    }

    private func makeStatus(from path: NWPath) -> Status {
        guard path.status == .satisfied else { return .unreachable }

        let type: ConnectionType
        if path.usesInterfaceType(.wifi) { type = .wifi }
        else if path.usesInterfaceType(.cellular) { type = .cellular }
        else if path.usesInterfaceType(.wiredEthernet) { type = .wired }
        else { type = .other }

        return Status(
            isReachable: true,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            connectionType: type
        )
    }

    private func notifyObservers(_ status: Status) {
        observers.forEach { $0(status) }
    }
}
