---
title: Datenschutzerklärung
locale: de
version: "1.0"
effective: "2026-10-04"
source: en
translation: machine
review: "MACHINE TRANSLATION of privacy.en.md v1.0: native legal review required before publishing (05 §5.3). The English version prevails."
---

# Taro Datenschutzerklärung

Version 1.0 · Gültig ab 4. Oktober 2026

## Wer wir sind

Taro ist eine Tarot-Tagebuch-App von Volodymyr Shyrochuk, einem einzelnen Entwickler und Unternehmer im Sinne des EU-Gesetzes über digitale Dienste („wir“, „uns“). Kontakt: volodymyr.shyrochuk@gmail.com. Anschrift und Telefon: Skrypnuka-Straße 278, 79049 Lwiw, Ukraine; Telefon: +380 93 815 0581.

## Zusammenfassung

- Es gibt kein Konto. Taro erstellt eine zufällige Installations-ID; wir fragen nie nach deinem Namen, deiner E-Mail-Adresse oder Telefonnummer.
- Dein Tagebuch, deine Karten und Deutungen bleiben auf deinem Gerät. Dein Tagebuch ist in der Gerätesicherung enthalten.
- Wenn du eine KI-Deutung anforderst, gehen deine Frage, das Legesystem, die gezogenen Karten und deine App-Sprache an unseren Server, der OpenAI bittet, die Deutung zu schreiben. Deine Frage wird auf unserem Server nicht gespeichert.
- Werbung wird von Google AdMob angezeigt, und erst nachdem du deine Einwilligungsentscheidungen getroffen hast.
- Du kannst deine Daten jederzeit in der App exportieren und löschen.

## Welche Daten wir verarbeiten

- **Installations-ID:** eine zufällige ID, die beim ersten Start erstellt wird. Sie verwaltet deine Deutungsguthaben, deine kostenlose Tagesdeutung und die Betrugsprävention.
- **Geräteschlüssel (nur Android):** ein Einweg-Hash der Android-Geräte-ID, der nur dazu dient, Missbrauch kostenloser Deutungen zu verhindern. Unter iOS speichert Apples DeviceCheck zum gleichen Zweck ein Bit; wir sehen nie eine Gerätekennung.
- **Zeitzone und App-Sprache:** um deine kostenlose Tagesdeutung um deine lokale Mitternacht zurückzusetzen und Deutungen in deiner Sprache zu schreiben.
- **Kaufdaten:** die Transaktions-ID des Stores, das Produkt und die gewährten Guthaben. Zahlungsdaten erhalten wir nie.
- **Deutungs-Metadaten:** Legesystem, Kartenanzahl, Sprache, Prompt-Version, Token-Anzahl, Kosten, Sicherheitskategorie und Ergebnis. Kein Fragetext.
- **Fragen für KI-Deutungen:** werden an den KI-Anbieter gesendet, um die Deutung zu schreiben, und nicht auf unserem Server gespeichert.
- **Deutungstexte:** werden auf unserem Server nur verschlüsselt aufbewahrt, bis dein Gerät sie empfangen hat.
- **Meldungen:** Wenn du eine Deutung meldest, speichern wir die Frage, den Deutungstext und deine optionale Notiz verschlüsselt, damit wir sie prüfen können.
- **Analysedaten:** wie die App genutzt wird (zum Beispiel welche Bildschirme geöffnet werden), über Google Analytics for Firebase, erst nach deinen Einwilligungsentscheidungen. Deine Frage, Deutung oder dein Tagebuchtext werden nie an die Analyse gesendet.
- **Absturzdaten:** Absturzberichte und Leistungsdaten über Firebase Crashlytics.
- **Werbedaten:** werden von Google AdMob verarbeitet (siehe Werbung).

## KI-Verarbeitung

KI-Deutungen werden von **OpenAI** (GPT-Modelle) geschrieben, das als unser Auftragsverarbeiter handelt. Derselbe Anbieter prüft Fragen und Deutungen auf Sicherheit (Moderation). Welches Modell eine Deutung schreibt, hängt von unserer Serverkonfiguration ab; wenn wir einen Anbieter hinzufügen oder wechseln, aktualisieren wir diese Erklärung und bitten dich in der App erneut um Erlaubnis.

- **Was gesendet wird:** deine Frage, das Legesystem, die gezogenen Karten und die App-Sprache. Wir senden nie deinen Namen, deine E-Mail-Adresse, Installations-ID oder Werbe-ID.
- **Training:** Nach den API-Bedingungen von OpenAI werden über die API gesendete Daten nicht zum Training seiner Modelle verwendet.
- **Aufbewahrung beim Anbieter:** OpenAI kann API-Anfragen bis zu 30 Tage zur Missbrauchserkennung aufbewahren und löscht sie dann; Moderationsanfragen werden nicht aufbewahrt.
- **Genauigkeit:** Deutungen werden von KI erzeugt. Sie können falsch oder unerwartet sein und dienen nur der Unterhaltung und Selbstreflexion.

Vor der ersten KI-Deutung erklärt die App dies und bittet um deine Erlaubnis. Du kannst sie jederzeit unter Einstellungen → KI-Deutungen widerrufen; klassische Deutungen funktionieren weiterhin ohne KI.

## Werbung

Taro zeigt Bannerwerbung und optionale Belohnungsvideos von Google AdMob. Bevor Werbung angefordert wird, fragt Googles Einwilligungsformular (UMP), wo gesetzlich erforderlich, nach deinen Entscheidungen. Unter iOS fragen wir danach über Apples App Tracking Transparency um Erlaubnis zum Tracking. Wenn du ablehnst, siehst du nicht personalisierte Werbung. Du kannst deine Entscheidungen jederzeit unter Einstellungen → Datenschutzeinstellungen ändern. AdMob kann deine Werbe-ID, einen aus deiner IP-Adresse abgeleiteten ungefähren Standort und Werbeinteraktionen nach Googles eigenen Bedingungen verarbeiten. Mit dem Kauf von „Bannerwerbung entfernen“ werden Banner entfernt.

## Käufe

Käufe werden von Apple (App Store) oder Google (Google Play) nach deren Bedingungen abgewickelt. Wir erhalten nur die Transaktionsdaten, die nötig sind, um dir deine Deutungen gutzuschreiben. Deutungsguthaben sind an diese Installation gebunden: Sie werden nach dem Löschen der App oder ihrer Daten nicht wiederhergestellt, und die Exportdatei enthält sie nicht. „Bannerwerbung entfernen“ kann wiederhergestellt werden.

## Rechtsgrundlagen (DSGVO)

- **Vertrag:** von dir angeforderte KI-Deutungen, einschließlich der Übermittlung deiner Frage an den KI-Anbieter; Käufe und Deutungsguthaben.
- **Einwilligung:** personalisierte Werbung und, wo erforderlich, Analyse.
- **Berechtigtes Interesse:** Betrugsprävention einschließlich des Geräteschlüssels; Absturzdaten, damit die App funktioniert.

Der KI-Erlaubnisschritt in der App dient der Transparenz und deiner Wahl; er ist nicht die Rechtsgrundlage der Verarbeitung.

## Aufbewahrung

- Deine Frage wird auf unserem Server nicht gespeichert.
- Der Deutungstext wird verschlüsselt aufbewahrt, bis dein Gerät den Empfang bestätigt, höchstens 7 Tage, und dann gelöscht.
- Gemeldete Deutungen werden 90 Tage aufbewahrt.
- Buchungs- und Kaufdaten werden 7 Jahre (Steuern, Erstattungen und Betrugsprävention) in pseudonymisierter Form aufbewahrt.
- Deutungs-Metadaten werden 13 Monate aufbewahrt.
- Daten zu Belohnungswerbung werden 13 Monate aufbewahrt.
- Tägliche Nutzungszähler werden 90 Tage aufbewahrt.
- Gerätezähler (unter Android an den Geräteschlüssel gebunden) werden 90 Tage aufbewahrt.
- Serverprotokolle werden 7 Tage aufbewahrt.
- Inaktive Installationen (24 Monate ohne Aktivität und ohne verbleibende Guthaben) werden nach 24 Monaten pseudonymisiert.

## Deine Rechte

- **Auskunft und Datenübertragbarkeit:** Einstellungen → Sicherung exportieren erstellt eine Datei mit deinem Tagebuch und deinen Deutungen.
- **Löschung:** Einstellungen → Alle Daten löschen löscht die Daten auf deinem Gerät und bittet unseren Server, deine Deutungen, Meldungen und Nutzungshistorie zu löschen. Deine verbleibenden Deutungsguthaben und „Bannerwerbung entfernen“ bleiben erhalten, weil es gekaufte Waren sind.
- **Widerspruch und Widerruf der Einwilligung:** Einstellungen → Datenschutzeinstellungen und Einstellungen → KI-Deutungen.
- **Beschwerde:** Du kannst dich bei deiner Datenschutzaufsichtsbehörde beschweren.
- **Datenschutzgesetze der US-Bundesstaaten:** Wir verkaufen deine personenbezogenen Daten nicht. Dem „Teilen“ für gezielte Werbung kannst du über das in US-Bundesstaaten angezeigte Datenschutzformular widersprechen.

Für jede Anfrage schreibe an volodymyr.shyrochuk@gmail.com und gib die Support-ID an, die in den Einstellungen angezeigt wird.

## Kinder

Taro richtet sich nicht an Kinder unter 16 Jahren, und wir erheben wissentlich keine Daten von ihnen.

## Sicherheit und internationale Übermittlungen

Daten werden bei der Übertragung verschlüsselt (HTTPS). Deutungstexte und Meldungen werden verschlüsselt gespeichert. Unser Server läuft bei Cloudflare; unsere Auftragsverarbeiter sind Cloudflare, OpenAI und Google (Firebase, AdMob). Sie können Daten außerhalb deines Landes verarbeiten, auch in den Vereinigten Staaten, auf Grundlage der Standardvertragsklauseln der Europäischen Kommission oder einer gleichwertigen Garantie.

## Änderungen

Wir aktualisieren diese Erklärung, wenn sich unsere Verarbeitung ändert, und zeigen hier die neue Version und das Gültigkeitsdatum. Betrifft eine Änderung die KI-Verarbeitung, bittet die App erneut um deine Erlaubnis.
