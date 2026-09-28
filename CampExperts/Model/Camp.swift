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

    /// The Apple Immersive Video master (.aivu). On device the masters
    /// live in the app's Documents container (copied one film at a time
    /// by scripts/sync_media.sh, so a 50 GB library survives interrupted
    /// transfers and weekly reinstalls); the bundle copy is the simulator
    /// path. Falls back to a flat master.mov, then to the proxy loop, so
    /// the journey stays demonstrable while films are still syncing.
    var masterURL: URL? {
        if let docs = FileManager.default.urls(for: .documentDirectory,
                                               in: .userDomainMask).first {
            let folder = docs.appending(path: "CampMedia/\(id)")
            // The sync writes master.ok only after the film lands whole;
            // without it, a transfer cut off mid-film would look playable.
            let complete = folder.appending(path: "master.ok")
            if FileManager.default.fileExists(atPath: complete.path(percentEncoded: false)) {
                return folder.appending(path: "master.aivu")
            }
        }
        return Bundle.main.url(forResource: "master", withExtension: "aivu",
                               subdirectory: "CampMedia/\(id)")
            ?? Bundle.main.url(forResource: "master", withExtension: "mov",
                               subdirectory: "CampMedia/\(id)")
            ?? loopURL
    }
}
