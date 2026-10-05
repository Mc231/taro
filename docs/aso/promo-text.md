# Promotional text and What's New

Source of truth: `apps/taro/store/aso.yaml` (`promotional_text`, `whats_new`) and `apps/taro/store/whats_new/{locale}.txt`. Release 1.0.0.

Rules:

- Promotional text ≤ 170 characters (Python `len()`), not indexed, editable without a new version.
- What's New ≤ 4,000 characters (ASC hides it on the very first version; it is kept for Play and for parity).
- Every feature mentioned ships in v1 (01 §6.1). The daily card (no AI) stays separate from "one free AI reading every day" (RC64).
- No prices, no urgency, no banned claims (05 §9.5); no other-platform names.
- After about 4 weeks, keep the evergreen promo below unless a feature release replaces it.

| Locale | Promotional text | Chars | What's New 1.0.0 | Chars |
|---|---|---|---|---|
| en | Ask a question, draw from an original deck and get a reading that explains every card in its place. One free AI reading every day. | 130 | Welcome to Taro. Ask a question and draw from an original deck, with one free AI reading every day, a free daily card, six spreads, a reflection journal and Learn mode for all 78 cards. | 185 |
| ar | اطرح سؤالًا واسحب من مجموعة بطاقات أصلية واحصل على قراءة تشرح كل بطاقة في موضعها. قراءة مجانية بالذكاء الاصطناعي كل يوم. | 120 | مرحبًا بك في Taro. اطرح سؤالًا واسحب من مجموعة بطاقات أصلية، مع قراءة مجانية بالذكاء الاصطناعي كل يوم، وبطاقة يومية مجانية، وست فرشات، ومذكرات للتأمل، ووضع التعلّم لجميع البطاقات الـ78. | 185 |
| de | Stell eine Frage, zieh aus einem eigenen Deck und erhalte eine Deutung, die jede Karte an ihrem Platz erklärt. Jeden Tag eine kostenlose KI-Deutung. | 148 | Willkommen bei Taro. Stell eine Frage und zieh aus einem eigenen Deck: jeden Tag eine kostenlose KI-Deutung, eine kostenlose Tageskarte, sechs Legungen, ein Reflexions-Journal und ein Lernmodus für alle 78 Karten. | 213 |
| es | Haz una pregunta, saca cartas de una baraja original y recibe una lectura que explica cada carta en su lugar. Una lectura con IA gratis cada día. | 145 | Te damos la bienvenida a Taro. Haz una pregunta y saca cartas de una baraja original, con una lectura con IA gratis cada día, una carta del día gratis, seis tiradas, un diario de reflexión y el modo Aprender con las 78 cartas. | 226 |
| fr | Posez une question, tirez dans un jeu original et recevez une lecture qui explique chaque carte à sa place. Une lecture IA offerte chaque jour. | 143 | Bienvenue dans Taro. Posez une question et tirez dans un jeu original, avec une lecture IA offerte chaque jour, une carte du jour gratuite, six tirages, un journal de réflexion et un mode Apprendre pour les 78 cartes. | 217 |
| it | Fai una domanda, pesca da un mazzo originale e ricevi una lettura che spiega ogni carta al suo posto. Una lettura IA gratuita ogni giorno. | 138 | Benvenuto in Taro. Fai una domanda e pesca da un mazzo originale, con una lettura IA gratuita ogni giorno, una carta del giorno gratuita, sei stese, un diario di riflessione e la modalità Impara per tutte le 78 carte. | 217 |
| ja | 質問をして、オリジナルデッキからカードを引けば、各カードをその位置に沿って解説するリーディングが届きます。AIリーディングは毎日1回無料。 | 69 | Taroへようこそ。質問をしてオリジナルデッキからカードを引きましょう。毎日1回無料のAIリーディング、無料の今日の一枚、6種類のスプレッド、振り返りジャーナル、78枚すべてを学べる学習モードを備えています。 | 104 |
| ko | 질문하고 오리지널 덱에서 카드를 뽑으면, 각 카드를 그 자리에 맞게 설명하는 리딩을 받을 수 있습니다. 매일 AI 리딩 1회 무료. | 73 | Taro에 오신 것을 환영합니다. 질문하고 오리지널 덱에서 카드를 뽑아 보세요. 매일 무료 AI 리딩 1회, 무료 오늘의 카드, 6가지 스프레드, 성찰 저널, 78장 전체를 다루는 학습 모드를 제공합니다. | 114 |
| nl | Stel een vraag, trek uit een eigen deck en krijg een lezing die elke kaart op haar plek uitlegt. Elke dag één gratis AI-lezing. | 127 | Welkom bij Taro. Stel een vraag en trek uit een eigen deck, met elke dag één gratis AI-lezing, een gratis dagkaart, zes leggingen, een reflectiedagboek en een leermodus voor alle 78 kaarten. | 190 |
| pt | Faça uma pergunta, tire cartas de um baralho original e receba uma leitura que explica cada carta no seu lugar. Uma leitura com IA grátis por dia. | 146 | Boas-vindas ao Taro. Faça uma pergunta e tire cartas de um baralho original, com uma leitura com IA grátis por dia, uma carta do dia grátis, seis tiragens, um diário de reflexão e o modo Aprender com as 78 cartas. | 213 |
| tr | Bir soru sor, özgün bir desteden kart çek ve her kartı yerine göre açıklayan bir okuma al. Her gün bir ücretsiz yapay zekâ okuması. | 131 | Taro'ya hoş geldin. Bir soru sor ve özgün bir desteden kart çek: her gün bir ücretsiz yapay zekâ okuması, ücretsiz günün kartı, altı açılım, bir yansıma günlüğü ve 78 kartın tamamı için öğrenme modu. | 199 |
| uk | Постав запитання, витягни карти з оригінальної колоди й отримай тлумачення, що пояснює кожну карту на її місці. Щодня одне безкоштовне тлумачення від ШІ. | 153 | Ласкаво просимо до Taro. Постав запитання й витягни карти з оригінальної колоди: щодня одне безкоштовне тлумачення від ШІ, безкоштовна карта дня, шість розкладів, щоденник роздумів і режим навчання для всіх 78 карт. | 215 |

## Play short descriptions (≤ 80)

| Locale | Title | Chars | Short description | Chars |
|---|---|---|---|---|
| en | Taro: Tarot Card Reading | 24 | AI tarot readings for reflection: daily card, spreads, journal | 62 |
| ar | Taro: قراءة التاروت | 19 | قراءات تاروت بالذكاء الاصطناعي للتأمل: بطاقة اليوم والفرشات والمذكرات | 69 |
| de | Taro: Tarot Karten legen | 24 | KI-Tarotdeutungen zur Reflexion: Tageskarte, Legungen, Journal | 62 |
| es | Taro: Lectura de Tarot | 22 | Lecturas de tarot con IA para reflexionar: carta del día, tiradas, diario | 73 |
| fr | Taro: Tirage de Tarot | 21 | Lectures de tarot par IA pour réfléchir : carte du jour, tirages, journal | 73 |
| it | Taro: Lettura dei Tarocchi | 26 | Letture dei tarocchi con IA per riflettere: carta del giorno, stese, diario | 75 |
| ja | Taro: タロット占い | 12 | 内省のためのAIタロットリーディング：今日の一枚、スプレッド、ジャーナル | 36 |
| ko | Taro: 타로 카드 운세 | 14 | 성찰을 위한 AI 타로 리딩: 오늘의 카드, 스프레드, 저널 | 33 |
| nl | Taro: Tarotkaarten Lezen | 24 | AI-tarotlezingen voor reflectie: dagkaart, leggingen, dagboek | 61 |
| pt | Taro: Leitura de Tarô | 21 | Leituras de tarô com IA para refletir: carta do dia, tiragens, diário | 69 |
| tr | Taro: Tarot Falı | 16 | Düşünmek için yapay zekâ tarot okumaları: günün kartı, açılımlar, günlük | 72 |
| uk | Taro: Карти Таро | 16 | Тлумачення таро від ШІ для роздумів: карта дня, розклади, щоденник | 66 |
