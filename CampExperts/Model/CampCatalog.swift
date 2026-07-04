//
//  CampCatalog.swift
//  CampExperts
//
//  PLACEHOLDER DATA.
//  Names, places, and coordinates are stand-ins, spread across real camp
//  country so the map reads correctly and no two lenses collide. Replace
//  all twenty entries with the client's camps — this file is the only
//  place camp identity lives. Folder names under Resources/CampMedia
//  must match these ids.
//

import Foundation

enum CampCatalog {

    static let all: [Camp] = [
        Camp(id: "c01", name: "Camp Wildwood",      place: "Bridgton, Maine",           latitude: 44.05, longitude: -70.73),
        Camp(id: "c02", name: "Camp Kettleford",    place: "Belgrade Lakes, Maine",     latitude: 44.52, longitude: -69.87),
        Camp(id: "c03", name: "Camp Bearcamp",      place: "Rangeley, Maine",           latitude: 44.93, longitude: -70.62),
        Camp(id: "c04", name: "Camp Pemetic",       place: "Mount Desert, Maine",       latitude: 44.33, longitude: -68.28),
        Camp(id: "c05", name: "Camp Ossipee",       place: "Wolfeboro, New Hampshire",  latitude: 43.60, longitude: -71.18),
        Camp(id: "c06", name: "Camp Squam",         place: "Holderness, New Hampshire", latitude: 43.83, longitude: -71.66),
        Camp(id: "c07", name: "Camp Coniston",      place: "Grantham, New Hampshire",   latitude: 43.49, longitude: -72.13),
        Camp(id: "c08", name: "Camp Abenaki",       place: "North Hero, Vermont",       latitude: 44.83, longitude: -73.28),
        Camp(id: "c09", name: "Camp Fairlee",       place: "Thetford, Vermont",         latitude: 43.90, longitude: -72.15),
        Camp(id: "c10", name: "Camp Greylock",      place: "Becket, Massachusetts",     latitude: 42.30, longitude: -73.08),
        Camp(id: "c11", name: "Camp Housatonic",    place: "Kent, Connecticut",         latitude: 41.72, longitude: -73.48),
        Camp(id: "c12", name: "Camp Wingate",       place: "Yarmouth, Massachusetts",   latitude: 41.70, longitude: -70.23),
        Camp(id: "c13", name: "Camp Quinebaug",     place: "Woodstock, Connecticut",    latitude: 41.95, longitude: -71.98),
        Camp(id: "c14", name: "Camp Dunmore",       place: "Salisbury, Vermont",        latitude: 43.90, longitude: -73.08),
        Camp(id: "c15", name: "Camp Sagamore",      place: "Raquette Lake, New York",   latitude: 43.81, longitude: -74.65),
        Camp(id: "c16", name: "Camp Ondawa",        place: "Lake George, New York",     latitude: 43.62, longitude: -73.58),
        Camp(id: "c17", name: "Camp Neversink",     place: "Liberty, New York",         latitude: 41.80, longitude: -74.75),
        Camp(id: "c18", name: "Camp Wallenpaupack", place: "Honesdale, Pennsylvania",   latitude: 41.58, longitude: -75.25),
        Camp(id: "c19", name: "Camp Poyntelle",     place: "Lakewood, Pennsylvania",    latitude: 41.99, longitude: -75.52),
        Camp(id: "c20", name: "Camp Kittatinny",    place: "Blairstown, New Jersey",    latitude: 40.97, longitude: -74.96),
    ]

    static func camp(_ id: String) -> Camp? {
        all.first { $0.id == id }
    }
}
