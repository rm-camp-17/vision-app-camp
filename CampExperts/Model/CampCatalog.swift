//
//  CampCatalog.swift
//  CampExperts
//
//  The twenty-two camps. Real data, verified August 2026 against each
//  camp's official site (see docs/camp-research.md for sources, coordinate
//  provenance, and confidence notes). Ids double as media folder names:
//  CampMedia/<id>/loop.mov + master.aivu.
//
//  Coordinates are camp-property points, not town centroids. Several
//  clusters sit within a couple of kilometers of each other (the three
//  Black-family camps in Greeley PA; the Belgrade Lakes cluster in Maine;
//  Poyntelle/Independent Lake), so MapAssembler runs a separation pass
//  before placing lenses — never assume a lens sits at the exact
//  projected point.
//

import Foundation

enum CampCatalog {

    static let all: [Camp] = [
        Camp(id: "academy",         name: "Academy Camps",             place: "Suffield, Connecticut",       latitude: 41.9851, longitude: -72.6508,
             style: "Sports-specialty", gender: "Co-Ed",          religion: "None",   sessions: "1-week stackable sessions"),
        Camp(id: "akiba",           name: "Camp Akiba",                place: "Reeders, Pennsylvania",       latitude: 40.9868, longitude: -75.3691,
             style: "Traditional",      gender: "Co-Ed",          religion: "Jewish heritage", sessions: "Full summer (6 weeks)"),
        Camp(id: "berkshire",       name: "Berkshire Trails Camp",     place: "Great Barrington, Massachusetts", latitude: 42.1727, longitude: -73.2926,
             style: "Traditional",      gender: "Co-Ed",          religion: "None",   sessions: "2–7 week sessions"),
        Camp(id: "birchmont",       name: "Pierce Camp Birchmont",     place: "Wolfeboro, New Hampshire",    latitude: 43.5991, longitude: -71.1177,
             style: "Traditional",      gender: "Co-Ed",          religion: "None",   sessions: "2–7 week sessions"),
        Camp(id: "brantlake",       name: "Brant Lake Camp",           place: "Brant Lake, New York",        latitude: 43.7164, longitude: -73.6944,
             style: "Traditional",      gender: "All Boys",       religion: "None",   sessions: "Full summer; 4-week half"),
        Camp(id: "caribou",         name: "Camp Caribou",              place: "Winslow, Maine",              latitude: 44.5397, longitude: -69.5605,
             style: "Traditional",      gender: "All Boys",       religion: "None",   sessions: "Full summer; two 4-week"),
        Camp(id: "eastwood",        name: "Camp Eastwood",             place: "Oakland, Maine",              latitude: 44.5951, longitude: -69.7626,
             style: "Traditional starter", gender: "Co-Ed",       religion: "None",   sessions: "1–2 week sessions"),
        Camp(id: "frenchwoods",     name: "French Woods Sports & Arts", place: "Hancock, New York",          latitude: 41.9131, longitude: -75.1997,
             style: "Teen sports & arts", gender: "Co-Ed",        religion: "None",   sessions: "2–10 week sessions"),
        Camp(id: "independentlake", name: "Independent Lake Camp",     place: "Thompson, Pennsylvania",      latitude: 41.8309, longitude: -75.4344,
             style: "Specialty hybrid",  gender: "Co-Ed",          religion: "None",   sessions: "2–8 week sessions"),
        Camp(id: "kenwood",         name: "Camps Kenwood & Evergreen", place: "Wilmot, New Hampshire",       latitude: 43.4548, longitude: -71.8839,
             style: "Traditional",      gender: "Brother/Sister", religion: "Nondenominational", sessions: "Full summer; 3.5-week halves"),
        Camp(id: "lakeowego",       name: "Lake Owego Camp",           place: "Greeley, Pennsylvania",       latitude: 41.4119, longitude: -75.0501,
             style: "Traditional",      gender: "All Boys",       religion: "Jewish traditions", sessions: "Full summer; 3.5-week halves"),
        Camp(id: "manitou",         name: "Camp Manitou",              place: "Oakland, Maine",              latitude: 44.5944, longitude: -69.7665,
             style: "Traditional",      gender: "All Boys",       religion: "None",   sessions: "Full summer; 3.5-week halves"),
        Camp(id: "medolark",        name: "Camp Med-O-Lark",           place: "Washington, Maine",           latitude: 44.2789, longitude: -69.3882,
             style: "Arts specialty",   gender: "Co-Ed",          religion: "None",   sessions: "2–8 week sessions"),
        Camp(id: "modin",           name: "Camp Modin",                place: "Belgrade, Maine",             latitude: 44.5270, longitude: -69.7905,
             style: "Traditional",      gender: "Co-Ed",          religion: "Jewish", sessions: "Full summer; 3.5-week halves"),
        Camp(id: "pineforest",      name: "Pine Forest Camp",          place: "Greeley, Pennsylvania",       latitude: 41.4087, longitude: -75.0150,
             style: "Traditional",      gender: "Co-Ed",          religion: "Jewish traditions", sessions: "Full summer; 4-week half"),
        Camp(id: "poyntelle",       name: "Camp Poyntelle",            place: "Poyntelle, Pennsylvania",     latitude: 41.8208, longitude: -75.4173,
             style: "Traditional",      gender: "Co-Ed",          religion: "Jewish", sessions: "2–7 week sessions"),
        Camp(id: "raquette",        name: "Raquette Lake Camps",       place: "Raquette Lake, New York",     latitude: 43.8201, longitude: -74.6567,
             style: "Traditional",      gender: "Brother/Sister", religion: "None",   sessions: "Full summer"),
        Camp(id: "somerset",        name: "Camp Somerset for Girls",   place: "Smithfield, Maine",           latitude: 44.6098, longitude: -69.7614,
             style: "Traditional",      gender: "All Girls",      religion: "None",   sessions: "Full summer; 2 and 3.5-week"),
        Camp(id: "southwoods",      name: "Camp Southwoods",           place: "Paradox, New York",           latitude: 43.8766, longitude: -73.7092,
             style: "Traditional",      gender: "Co-Ed",          religion: "None",   sessions: "2–8 week sessions"),
        Camp(id: "timbertops",      name: "Camp Timber Tops",          place: "Greeley, Pennsylvania",       latitude: 41.4089, longitude: -75.0423,
             style: "Traditional",      gender: "All Girls",      religion: "Jewish traditions", sessions: "Full summer; half sessions"),
        Camp(id: "windsor",         name: "Windsor Mountain",          place: "Windsor, New Hampshire",      latitude: 43.1149, longitude: -72.0151,
             style: "Traditional international", gender: "Co-Ed", religion: "None",   sessions: "2–8 week sessions"),
        Camp(id: "woodward",        name: "Camp Woodward",               place: "Woodward, Pennsylvania",      latitude: 40.9018, longitude: -77.3684,
             style: "Action sports",    gender: "Co-Ed",          religion: "None",   sessions: "Weekly sessions"),
    ]

    static func camp(_ id: String) -> Camp? {
        all.first { $0.id == id }
    }

    /// The welcome reel that plays when a guest puts the headset on.
    /// Not part of `all` — it never appears on the map; it only resolves
    /// media from `CampMedia/_intro/`. Optional like all media: no file,
    /// no intro, straight to the map.
    static let intro = Camp(
        id: "_intro", name: "Camp Experts", place: "",
        latitude: 0, longitude: 0,
        style: "", gender: "", religion: "", sessions: "")
}
