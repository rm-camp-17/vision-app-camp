//
//  Loc.swift
//  CampExperts
//
//  Two languages, one file. Everything the app itself says can speak
//  French; camp names and geography never translate. Chips translate
//  through a small dictionary and degrade gracefully to English when a
//  data string has no mapping — wrong French is worse than no French.
//

import Foundation

enum Lang { case en, fr }

enum Loc {

    // MARK: - Brand mark & toggles

    static func instruction(_ l: Lang) -> String {
        l == .fr ? "REGARDEZ UN CAMP — TOUCHEZ POUCE ET INDEX POUR VISITER"
                 : "LOOK AT A CAMP — TAP YOUR THUMB AND FINGER TOGETHER TO VISIT"
    }
    static func attractInvite(_ l: Lang) -> String {
        l == .fr ? "TOUCHEZ POUCE ET INDEX POUR COMMENCER"
                 : "TAP YOUR THUMB AND FINGER TOGETHER TO BEGIN"
    }
    static func byMap(_ l: Lang) -> String {
        l == .fr ? "PAR CARTE" : "BY MAP"
    }
    static func byType(_ l: Lang) -> String {
        l == .fr ? "PAR TYPE DE CAMP" : "BY CAMP TYPE"
    }

    // MARK: - Focus card

    static func confirmLine(_ l: Lang) -> String {
        l == .fr ? "PINCEZ ENCORE POUR ENTRER" : "PINCH IT AGAIN TO GO INSIDE"
    }
    static func declineLine(_ l: Lang) -> String {
        l == .fr ? "PINCEZ AILLEURS POUR LA CARTE" : "PINCH AWAY FOR THE MAP"
    }

    // MARK: - Gesture hints

    static func skipHint(_ l: Lang) -> String {
        l == .fr ? "ESSAYEZ — TOUCHEZ POUCE ET INDEX POUR PASSER LA SUITE"
                 : "TRY IT — TAP YOUR THUMB AND FINGER TOGETHER TO SKIP AHEAD"
    }
    static func returnHint(_ l: Lang) -> String {
        l == .fr ? "TOUCHEZ POUCE ET INDEX À TOUT MOMENT POUR REVENIR"
                 : "TAP YOUR THUMB AND FINGER TOGETHER ANYTIME TO COME BACK"
    }

    // MARK: - Farewell

    static func farewellTitle(_ l: Lang) -> String {
        l == .fr ? "C'ÉTAIT VOS TROIS CAMPS" : "THAT WAS YOUR THREE CAMPS"
    }
    static func farewellNudge(_ l: Lang) -> String {
        l == .fr ? "RENDEZ LE CASQUE — TROUVONS LE VÔTRE"
                 : "HAND THE HEADSET BACK — LET'S FIND YOURS"
    }

    // MARK: - Browse sections

    static func sectionTraditional(_ l: Lang) -> String {
        l == .fr ? "CAMPS TRADITIONNELS" : "TRADITIONAL CAMPS"
    }
    static func sectionSports(_ l: Lang) -> String {
        l == .fr ? "SPORTS & ACTION" : "SPORTS & ACTION"
    }
    static func sectionArts(_ l: Lang) -> String {
        l == .fr ? "ARTS & CRÉATIVITÉ" : "ARTS & CREATIVE"
    }
    static func sectionShort(_ l: Lang) -> String {
        l == .fr ? "SÉJOURS COURTS & FLEXIBLES" : "SHORT & FLEXIBLE SESSIONS"
    }
    static func sectionJewish(_ l: Lang) -> String {
        l == .fr ? "VALEURS JUIVES & TRADITIONS" : "JEWISH VALUES & TRADITIONS"
    }
    static func sectionBoys(_ l: Lang) -> String {
        l == .fr ? "GARÇONS" : "ALL-BOYS"
    }
    static func sectionGirls(_ l: Lang) -> String {
        l == .fr ? "FILLES" : "ALL-GIRLS"
    }
    static func sectionSiblings(_ l: Lang) -> String {
        l == .fr ? "FRÈRES & SŒURS" : "BROTHER & SISTER"
    }

    // MARK: - Trait chips (dictionary with graceful English fallback)

    private static let chipFR: [String: String] = [
        "Co-Ed": "Mixte",
        "All Boys": "Garçons",
        "All Girls": "Filles",
        "Brother/Sister": "Frères & sœurs",
        "Traditional": "Traditionnel",
        "Traditional starter": "Premier camp",
        "Traditional international": "Traditionnel international",
        "Sports-specialty": "Spécialité sports",
        "Action sports": "Sports d'action",
        "Arts specialty": "Spécialité arts",
        "Specialty hybrid": "Multi-spécialités",
        "Teen sports & arts": "Ados — sports & arts",
        "Jewish values": "Valeurs juives",
        "Full summer": "Été complet",
        "Full summer (6 weeks)": "Été complet (6 semaines)",
        "Weekly sessions": "Séjours à la semaine",
        "1-week stackable sessions": "Séjours d'une semaine",
        "1–2 week sessions": "Séjours de 1 à 2 semaines",
        "2–7 week sessions": "Séjours de 2 à 7 semaines",
        "2–8 week sessions": "Séjours de 2 à 8 semaines",
        "2–10 week sessions": "Séjours de 2 à 10 semaines",
        "Full summer; 4-week half": "Été complet; demi-séjour 4 sem.",
        "Full summer; two 4-week": "Été complet; deux fois 4 sem.",
        "Full summer; 3.5-week halves": "Été complet; demi-séjours 3,5 sem.",
        "Full summer; half sessions": "Été complet; demi-séjours",
        "Full summer; 2 and 3.5-week": "Été complet; 2 et 3,5 sem.",
    ]

    static func chip(_ value: String, _ l: Lang) -> String {
        guard l == .fr else { return value }
        return chipFR[value] ?? value
    }
}
