# Kurzfassung

Stand: 2026-05-24.

## Ergebnis Der Recherche

Die wiederkehrende Kritik an Jodel betrifft vor allem:

- Datenschutz und Pseudo-Anonymitaet: Jodel ist nach aussen anonym, verknuepft Aktivitaeten intern aber mit einem zufaelligen Nutzerwert. Heise berichtete zudem ueber einen Datenschutzvorfall mit E-Mail-Adressen und verweist auf Forschung, bei der Standorte aus Jodel-Nachrichten sehr genau bestimmt werden konnten.
- Standort-Risiko: Hyperlokale Feeds koennen Personen ueber Entfernung, Uhrzeit, Ort und lokalen Kontext identifizierbar machen.
- Moderation: Jodel setzt laut eigener Dokumentation auf automatisierte Systeme, Community-Meldungen, Voting und Nutzer-Moderatoren. Kritik daran ist, dass Community-basierte Moderation inkonsistent, langsam oder mehrheitsgetrieben wirken kann.
- Missbrauchsrisiken: Hass, Belaestigung, Doxxing, Geruechte und gezielte Angriffe sind besonders riskant, weil lokale Kontexte klein und wiedererkennbar sind.
- Jugendschutz und App-Store-Compliance: UGC-Apps brauchen sichtbare Melde-, Blockier-, Filter- und Supportwege. Diese muessen Teil des MVP sein, nicht spaetere Admin-Funktionen.

## Produktentscheidung

Der neue App-Ansatz heisst vorlaeufig `Kiezio`.

Kiezio soll nicht "Jodel mit anderem Namen" werden, sondern eine sichere hyperlokale Community:

- pseudonym statt voll anonym;
- private Verantwortlichkeit statt oeffentlicher Klarnamen;
- grobe Standortbereiche statt exakter Distanz;
- 1:1 Videochat nur freiwillig, pseudonym, mit Sicherheits-Gate und sichtbaren Melde-/Blockier-/Auflegen-Kontrollen;
- transparente Moderation mit Regel-ID und Einspruch;
- Report, Block, Mute und Account-Loeschung ab dem ersten Testbuild;
- menschliche Pruefung fuer schwere Faelle wie Doxxing, Drohungen, Hass und Stalking.

## Namensentscheidung

`Kiezio` ist ein Arbeitsname mit niedrigerem erkennbaren Konfliktrisiko als gepruefte Alternativen wie `Naybo`, `Nahbar`, `Orbiq`, `Ankra`, `Kiezfunk`, `Kiezklar` oder `Nahsignal`.

Wichtig: Das ist nur eine offene Web- und App-Store-Vorpruefung. Vor Launch braucht es formale Markenpruefung fuer DPMA, EUIPO, WIPO, USPTO, App Stores, Domains und Social Handles.

## Naechster Schritt

Vor Implementierung sollte entschieden werden:

- erste Zielregion oder Campus;
- 18+ Beta oder anderes Altersmodell;
- Backend-Stack;
- Location-Grid-System;
- Moderationsbesetzung fuer private Beta;
- wie WebRTC-Signaling und Moderations-Metadaten fuer echte Videoanrufe angebunden werden.
