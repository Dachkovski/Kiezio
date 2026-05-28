import Foundation

enum MockSpaces {
    static let area = KiezioSpace(id: "area", title: "Umgebung", subtitle: "Alles Wichtige direkt um dich herum", kind: .area, systemImage: "location.circle", tintName: "teal")
    static let questions = KiezioSpace(id: "questions", title: "Fragen", subtitle: "Schnelle Antworten von Leuten vor Ort", kind: .interest, systemImage: "questionmark.bubble", tintName: "blue")
    static let recommendations = KiezioSpace(id: "recommendations", title: "Empfehlungen", subtitle: "Cafes, Werkstaetten, Orte und Tipps", kind: .interest, systemImage: "hand.thumbsup", tintName: "green")
    static let help = KiezioSpace(id: "help", title: "Hilfe", subtitle: "Spontane Unterstuetzung in der Naehe", kind: .help, systemImage: "hands.sparkles", tintName: "teal")
    static let events = KiezioSpace(id: "events", title: "Events", subtitle: "Was heute und diese Woche passiert", kind: .events, systemImage: "calendar", tintName: "plum")
    static let mobility = KiezioSpace(id: "mobility", title: "Mobilitaet", subtitle: "Oepnv, Fahrrad, Verkehr und Warnungen", kind: .interest, systemImage: "tram", tintName: "gold")
    static let campus = KiezioSpace(id: "campus", title: "Campus", subtitle: "Uni, Lernen und Leute in der Naehe", kind: .campus, systemImage: "graduationcap", tintName: "blue")
    static let work = KiezioSpace(id: "work", title: "Arbeit", subtitle: "Lunch, Pendeln und After-Work", kind: .work, systemImage: "briefcase", tintName: "green")

    static var all: [KiezioSpace] {
        [area, questions, recommendations, help, events, mobility, campus, work]
    }
}
