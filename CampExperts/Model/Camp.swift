//
//  Camp.swift
//  CampExperts
//

import Foundation

/// One camp: a point on the map, a living loop, an immersive master.
struct Camp: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    /// "Lake George, New York" — the second, quieter line of the label.
    let place: String
    let latitude: Double
    let longitude: Double

    /// Program identity, verified against each camp's official site.
    /// Not yet surfaced in the UI; available for filtering and future
    /// label treatments.
    let style: String       // "Traditional", "Sports-specialty", "Arts specialty", …
    let gender: String      // "Co-Ed", "Brother/Sister", "All Girls", "All Boys"
    let religion: String    // "None", "Jewish", "Nondenominational", …
    let sessions: String    // "Full summer", "Session-based", …

    /// The small, muted, flat proxy loop for the map lens.
    /// Never the immersive master — wrong projection, three orders of
    /// magnitude too heavy for a thumbnail.
    var loopURL: URL? {
        Bundle.main.url(forResource: "loop", withExtension: "mov",
                        subdirectory: "CampMedia/\(id)")
    }

    /// The Apple Immersive Video master (.aivu). Falls back to a flat
    /// master.mov, then to the proxy loop, so the core journey stays
    /// demonstrable before real footage lands.
    var masterURL: URL? {
        Bundle.main.url(forResource: "master", withExtension: "aivu",
                        subdirectory: "CampMedia/\(id)")
            ?? Bundle.main.url(forResource: "master", withExtension: "mov",
                               subdirectory: "CampMedia/\(id)")
            ?? loopURL
    }
}
