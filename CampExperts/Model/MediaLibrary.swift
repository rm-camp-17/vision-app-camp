//
//  MediaLibrary.swift
//  CampExperts
//
//  Films reach the headset in 256 MB parts (scripts/sync_media.sh), so a
//  transfer cut short by the headset sleeping loses at most one part.
//  Each film's parts land in
//
//      Documents/CampMedia/<id>/incoming/<total bytes>/part-aaa, part-aab, …
//      Documents/CampMedia/<id>/incoming/<total bytes>/ready-<part count>
//
//  and the ready flag is sent last. Whenever the app launches or a guest
//  puts the headset on, every fully delivered film is stitched into
//  master.aivu and stamped with master.ok (its byte count); Camp.masterURL
//  only trusts a film whose size matches its stamp. A re-sent film simply
//  arrives as a new batch and replaces the old one the same way.
//

import Foundation

enum MediaLibrary {

    static var root: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appending(path: "CampMedia")
    }

    @MainActor private static var busy = false

    /// Stitch every fully delivered film, off the main thread. Safe to
    /// call as often as you like; overlapping calls are dropped.
    @MainActor
    static func assembleDeliveredFilms() {
        guard !busy else { return }
        busy = true
        Task.detached(priority: .utility) {
            assembleAll()
            await MainActor.run { busy = false }
        }
    }

    private static func assembleAll() {
        let fm = FileManager.default
        guard let root,
              let camps = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        else { return }

        for camp in camps {
            let incoming = camp.appending(path: "incoming")
            guard let batches = try? fm.contentsOfDirectory(at: incoming, includingPropertiesForKeys: nil)
            else { continue }
            for batch in batches {
                guard let expected = Int64(batch.lastPathComponent),
                      let names = try? fm.contentsOfDirectory(atPath: batch.path(percentEncoded: false)),
                      let ready = names.first(where: { $0.hasPrefix("ready-") }),
                      let count = Int(ready.dropFirst("ready-".count))
                else { continue }
                let parts = names.filter { $0.hasPrefix("part-") }.sorted()
                let total = parts.reduce(Int64(0)) { $0 + size(of: batch.appending(path: $1)) }
                guard parts.count == count, total == expected else { continue }

                trace("stitching \(camp.lastPathComponent) (\(parts.count) parts); available memory \(availableMemoryMB) MB")
                if stitch(parts.map { batch.appending(path: $0) }, into: camp, bytes: expected) {
                    // Also clears any stale, half-delivered older batch.
                    try? fm.removeItem(at: incoming)
                    trace("assembled film \(camp.lastPathComponent)")
                    break
                }
            }
        }
    }

    private static func stitch(_ parts: [URL], into camp: URL, bytes: Int64) -> Bool {
        let fm = FileManager.default
        let working = camp.appending(path: "master.aivu.assembling")
        let film = camp.appending(path: "master.aivu")
        let stamp = camp.appending(path: "master.ok")
        try? fm.removeItem(at: working)
        guard fm.createFile(atPath: working.path(percentEncoded: false), contents: nil),
              let out = try? FileHandle(forWritingTo: working)
        else { return false }
        do {
            for part in parts {
                let input = try FileHandle(forReadingFrom: part)
                defer { try? input.close() }
                // Drain each 8 MB chunk immediately: without a pool per
                // chunk, a long stitch keeps every chunk alive at once
                // (gigabytes) until the whole film is done.
                var more = true
                while more {
                    try autoreleasepool {
                        if let chunk = try input.read(upToCount: 8 << 20), !chunk.isEmpty {
                            try out.write(contentsOf: chunk)
                        } else {
                            more = false
                        }
                    }
                }
            }
            try out.close()
            guard size(of: working) == bytes else { return false }
            // Unstamp before swapping, so a crash mid-swap can never leave
            // a stamp vouching for the wrong bytes.
            try? fm.removeItem(at: stamp)
            try? fm.removeItem(at: film)
            try fm.moveItem(at: working, to: film)
            try String(bytes).write(to: stamp, atomically: true, encoding: .utf8)
            return true
        } catch {
            try? out.close()
            try? fm.removeItem(at: working)
            trace("assembling \(camp.lastPathComponent) failed: \(error.localizedDescription)")
            return false
        }
    }

    static func size(of url: URL) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        return (attrs?[.size] as? NSNumber)?.int64Value ?? -1
    }
}
