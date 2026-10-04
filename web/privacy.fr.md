---
title: Politique de confidentialité
locale: fr
version: "1.0"
effective: "2026-10-04"
source: en
translation: machine
review: "MACHINE TRANSLATION of privacy.en.md v1.0: native legal review required before publishing (05 §5.3). The English version prevails."
---

# Politique de confidentialité de Taro

Version 1.0 · En vigueur depuis le 4 octobre 2026

## Qui sommes-nous

Taro est une application de journal de tarot créée par Volodymyr Shyrochuk, développeur individuel et professionnel au sens du règlement européen sur les services numériques (« nous »). Contact : volodymyr.shyrochuk@gmail.com. Adresse et téléphone du professionnel : 278, rue Skrypnuka, 79049 Lviv, Ukraine ; téléphone : +380 93 815 0581.

## En bref

- Il n’y a pas de compte. Taro crée un identifiant d’installation aléatoire ; nous ne demandons jamais votre nom, votre e-mail ou votre numéro de téléphone.
- Votre journal, vos cartes et vos lectures restent sur votre appareil. Votre journal est inclus dans la sauvegarde de l’appareil.
- Lorsque vous demandez une lecture par IA, votre question, le tirage, les cartes tirées et la langue de l’app sont envoyés à notre serveur, qui demande à OpenAI de rédiger l’interprétation. Votre question n’est pas conservée sur notre serveur.
- Les publicités sont affichées par Google AdMob, et seulement après que vous avez fait vos choix de consentement.
- Vous pouvez exporter et supprimer vos données depuis l’app à tout moment.

## Données que nous traitons

- **Identifiant d’installation :** un identifiant aléatoire créé au premier lancement. Il sert à vos crédits de lecture, à votre lecture quotidienne gratuite et à la prévention de la fraude.
- **Clé d’appareil (Android uniquement) :** un hachage à sens unique de l’identifiant de l’appareil Android, utilisé uniquement pour empêcher l’abus des lectures gratuites. Sur iOS, DeviceCheck d’Apple enregistre un bit dans le même but ; nous ne voyons jamais d’identifiant d’appareil.
- **Fuseau horaire et langue de l’app :** pour réinitialiser votre lecture quotidienne gratuite à minuit heure locale et rédiger les lectures dans votre langue.
- **Données d’achat :** l’identifiant de transaction du store, le produit et les crédits accordés. Nous ne recevons jamais vos données de paiement.
- **Métadonnées de lecture :** tirage, nombre de cartes, langue, version du prompt, nombre de tokens, coût, catégorie de sécurité et résultat. Sans le texte de la question.
- **Questions des lectures par IA :** envoyées au fournisseur d’IA pour rédiger la lecture, et non conservées sur notre serveur.
- **Textes des lectures :** conservés chiffrés sur notre serveur uniquement jusqu’à ce que votre appareil les ait reçus.
- **Signalements :** si vous signalez une lecture, nous conservons, chiffrés, la question, le texte de la lecture et votre note facultative afin de l’examiner.
- **Statistiques :** l’utilisation de l’app (par exemple les écrans ouverts), via Google Analytics for Firebase, seulement après vos choix de consentement. Nous n’envoyons jamais votre question, votre lecture ou le texte de votre journal aux statistiques.
- **Données de plantage :** rapports de plantage et données de performance, via Firebase Crashlytics.
- **Données publicitaires :** traitées par Google AdMob (voir Publicité).

## Traitement par l’IA

Les lectures par IA sont rédigées par **OpenAI** (modèles GPT), qui agit en tant que sous-traitant. Le même fournisseur vérifie la sécurité des questions et des lectures (modération). Le modèle qui rédige une lecture dépend de la configuration de notre serveur ; si nous ajoutons ou changeons de fournisseur, nous mettrons à jour cette politique et vous redemanderons votre autorisation dans l’app.

- **Ce qui est envoyé :** votre question, le tirage, les cartes tirées et la langue de l’app. Nous n’envoyons jamais votre nom, votre e-mail, votre identifiant d’installation ni votre identifiant publicitaire.
- **Entraînement :** selon les conditions de l’API d’OpenAI, les données envoyées via l’API ne sont pas utilisées pour entraîner ses modèles.
- **Conservation par le fournisseur :** OpenAI peut conserver les requêtes API jusqu’à 30 jours pour détecter les abus, puis les supprime ; les requêtes de modération ne sont pas conservées.
- **Exactitude :** les lectures sont générées par une IA. Elles peuvent être erronées ou inattendues et servent uniquement au divertissement et à la réflexion.

Avant la première lecture par IA, l’app vous l’explique et vous demande votre autorisation. Vous pouvez la retirer à tout moment dans Réglages → Lectures par IA ; les lectures classiques continuent de fonctionner sans IA.

## Publicité

Taro affiche des bannières publicitaires et des vidéos récompensées facultatives de Google AdMob. Avant toute demande de publicité, le formulaire de consentement de Google (UMP) recueille vos choix lorsque la loi l’exige. Sur iOS, nous demandons ensuite l’autorisation de suivi via App Tracking Transparency d’Apple. Si vous refusez, vous voyez des publicités non personnalisées. Vous pouvez modifier vos choix à tout moment dans Réglages → Choix de confidentialité. AdMob peut traiter votre identifiant publicitaire, une localisation approximative déduite de votre adresse IP et vos interactions avec les publicités selon ses propres conditions. L’achat de Supprimer les bannières publicitaires supprime les bannières.

## Achats

Les achats sont traités par Apple (App Store) ou Google (Google Play) selon leurs conditions. Nous recevons uniquement les informations de transaction nécessaires pour vous créditer vos lectures. Les crédits de lecture sont liés à cette installation : ils ne sont pas restaurés après la suppression de l’app ou de ses données, et le fichier d’export ne les contient pas. Supprimer les bannières publicitaires peut être restauré.

## Bases légales (RGPD)

- **Contrat :** les lectures par IA que vous demandez, y compris l’envoi de votre question au fournisseur d’IA ; les achats et les crédits de lecture.
- **Consentement :** publicités personnalisées et, si nécessaire, statistiques.
- **Intérêt légitime :** prévention de la fraude, y compris la clé d’appareil ; données de plantage pour que l’app fonctionne.

L’étape d’autorisation de l’IA dans l’app sert à la transparence et à votre choix ; elle n’est pas la base légale du traitement.

## Durées de conservation

- Votre question n’est pas conservée sur notre serveur.
- Le texte de la lecture est conservé chiffré jusqu’à ce que votre appareil en confirme la réception, au maximum 7 jours, puis il est supprimé.
- Les lectures signalées sont conservées 90 jours.
- Les écritures comptables et les données d’achat sont conservées 7 ans (fiscalité, remboursements et prévention de la fraude) sous forme pseudonymisée.
- Les métadonnées de lecture sont conservées 13 mois.
- Les données des publicités récompensées sont conservées 13 mois.
- Les compteurs d’utilisation quotidienne sont conservés 90 jours.
- Les compteurs d’appareil (liés à la clé d’appareil sur Android) sont conservés 90 jours.
- Les journaux du serveur sont conservés 7 jours.
- Les installations inactives (24 mois sans activité et sans crédits restants) sont pseudonymisées après 24 mois.

## Vos droits

- **Accès et portabilité :** Réglages → Exporter une sauvegarde crée un fichier contenant votre journal et vos lectures.
- **Effacement :** Réglages → Supprimer toutes les données efface les données de votre appareil et demande à notre serveur d’effacer vos lectures, signalements et historique d’utilisation. Vos crédits de lecture restants et Supprimer les bannières publicitaires sont conservés, car ce sont des biens achetés.
- **Opposition et retrait du consentement :** Réglages → Choix de confidentialité et Réglages → Lectures par IA.
- **Réclamation :** vous pouvez déposer une réclamation auprès de votre autorité de protection des données.
- **Lois des États américains sur la vie privée :** nous ne vendons pas vos informations personnelles. Vous pouvez refuser le « partage » à des fins de publicité ciblée via le formulaire de confidentialité affiché dans les États américains.

Pour toute demande, écrivez à volodymyr.shyrochuk@gmail.com en indiquant l’ID d’assistance affiché dans les Réglages.

## Enfants

Taro ne s’adresse pas aux enfants de moins de 16 ans, et nous ne collectons pas sciemment leurs données.

## Sécurité et transferts internationaux

Les données sont chiffrées en transit (HTTPS). Les textes des lectures et les signalements sont chiffrés au repos. Notre serveur fonctionne sur Cloudflare ; nos sous-traitants sont Cloudflare, OpenAI et Google (Firebase, AdMob). Ils peuvent traiter des données hors de votre pays, y compris aux États-Unis, sur la base des clauses contractuelles types de la Commission européenne ou d’une garantie équivalente.

## Modifications

Nous mettrons à jour cette politique lorsque nos traitements changent et indiquerons ici la nouvelle version et sa date d’entrée en vigueur. Si une modification concerne le traitement par l’IA, l’app vous redemandera votre autorisation.
