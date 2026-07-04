//
//  IdleEngine.swift
//  CampExperts
//
//  If nobody chooses, the space chooses — a different camp every time.
//  A shuffled bag guarantees no repeats until all twenty have been seen.
//

import Foundation

@MainActor
final class IdleEngine {

    var onChoose: ((Camp) -> Void)?

    private var clock: Task<Void, Never>?
    private var bag: [Camp] = []

    /// (Re)start the countdown. Called on every sign of a person:
    /// boot finishing, stray pinches, returning from a visit.
    func arm() {
        clock?.cancel()
        clock = Task { [weak self] in
            try? await Task.sleep(for: Design.idleDelay)
            guard !Task.isCancelled, let self else { return }
            self.onChoose?(self.draw())
        }
    }

    func cancel() {
        clock?.cancel()
    }

    private func draw() -> Camp {
        if bag.isEmpty { bag = CampCatalog.all.shuffled() }
        return bag.removeFirst()
    }
}
