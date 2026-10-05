# Keywords, name and subtitle (App Store), all locales

Source of truth: `apps/taro/store/aso.yaml` (`localizations`). Counts are Python `len()`, which matches App Store Connect (including CJK). Strategy per 05 §9.3 (Blocks method): the name carries the head term, the subtitle the daily card / journal / spreads cluster, the keyword field long-tail words that combine with both.

Rules checked for every locale:

- Name ≤ 30, subtitle ≤ 30, keywords ≤ 100; comma-separated, no spaces, no duplicates.
- No keyword repeats a word already in the locale's name or subtitle.
- `Taro` stays Latin in every locale's name (brand).
- `yes,no` and translations removed: v1 has no yes/no spread (RC2). `love` kept: the `relationship` spread ships.
- `ai` kept only while readings are AI-written.
- Excluded everywhere (05 §9.5): psychic, medium, clairvoyant, fortune teller, horoscope/astrology, accuracy words, competitor and deck trademarks (Rider-Waite, Thoth, Co-Star, Labyrinthos, Golden Thread). `free` and its translations only in the keyword field, never in name/subtitle.
- Rotation after 4 weeks: replace zero-impression words from the 05 §9.3 rotation pool, logged in `ASO_TRACKER.md`.

---

## en (en-US)

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Tarot Card Reading` | 24/30 |
| Subtitle | `Daily Card, Journal & Spreads` | 29/30 |
| Keywords | `ai,oracle,deck,meanings,love,celtic,cross,major,arcana,learn,reflection,mindful,guide,insight,symbol` | 100/100 |

Name carries the head term "tarot card reading"; subtitle the daily card / journal / spreads cluster. Keywords combine with both: "ai tarot", "tarot meanings", "love tarot" (Relationship spread ships), "celtic cross", "major arcana", "learn tarot", "oracle deck". `yes,no` dropped (no yes/no spread, RC2); `symbol` added from the rotation pool. Plurals omitted where Apple matches them.

---

## ar (ar-SA)

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: قراءة التاروت` | 19/30 |
| Subtitle | `بطاقة اليوم ومذكرات وفرشات` | 26/30 |
| Keywords | `تاروت,بطاقات,أوراق,معنى,حب,الصليب,السلتي,الأركانا,أوراكل,ذكاء,اصطناعي,تأمل,تعلم` | 79/100 |

`تاروت` repeated as the bare stem because the name uses the definite form `التاروت`. `نعم,لا` dropped (RC2). Headroom (~21 chars) left for ASC search-term data after 4 weeks.

---

## de

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Tarot Karten legen` | 24/30 |
| Subtitle | `Tageskarte, Journal, Legungen` | 29/30 |
| Keywords | `kartenlegen,orakel,bedeutung,liebe,keltisches,kreuz,große,arkana,ki,deck,lernen,reflexion,anfänger` | 98/100 |

`kartenlegen` is the common German query; `ja,nein` dropped (RC2) and replaced by `anfänger` from the rotation pool. `tarot` already in the name.

---

## es

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Lectura de Tarot` | 22/30 |
| Subtitle | `Carta del día, diario, tiradas` | 30/30 |
| Keywords | `cartas,oráculo,significado,amor,cruz,celta,arcanos,mayores,ia,baraja,aprender,reflexión,novatos` | 95/100 |

`sí,no` dropped (RC2), `novatos` added (principiantes would overflow). `tarot` and `lectura` already in the name.

---

## fr

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Tirage de Tarot` | 21/30 |
| Subtitle | `Carte du jour, journal intime` | 29/30 |
| Keywords | `cartes,oracle,signification,amour,croix,celtique,arcanes,majeurs,ia,jeu,apprendre,réflexion,débutant` | 100/100 |

`oui,non` dropped (RC2), `débutant` added from the rotation pool. `tirage` and `tarot` already in the name.

---

## it

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Lettura dei Tarocchi` | 26/30 |
| Subtitle | `Carta del giorno e diario` | 25/30 |
| Keywords | `tarot,carte,oracolo,significato,amore,croce,celtica,arcani,maggiori,ia,mazzo,imparare,stese` | 91/100 |

`tarot` kept because Italian users search both "tarot" and "tarocchi". `sì,no` dropped (RC2).

---

## ja

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: タロット占い` | 12/30 |
| Subtitle | `今日の一枚・ジャーナル・スプレッド` | 17/30 |
| Keywords | `タロットカード,カードの意味,恋愛,大アルカナ,小アルカナ,ケルト十字,オラクル,AI,無料,内省,日記,デッキ,初心者,学習` | 63/100 |

占い is the normal genre noun (05 §9.3, allowed). `イエスノー` dropped (RC2). 無料 only in keywords (banned in name/subtitle, 05 §9.5). ~37 chars headroom for ASC data.

---

## ko

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: 타로 카드 운세` | 14/30 |
| Subtitle | `오늘의 카드, 저널, 스프레드` | 16/30 |
| Keywords | `타로카드,타로점,연애,의미,메이저,마이너,아르카나,켈틱크로스,오라클,AI,무료,성찰,일기,덱,초보` | 54/100 |

운세 is the normal genre noun (allowed). `예스노` dropped (RC2). 무료 only in keywords. ~46 chars headroom.

---

## nl

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Tarotkaarten Lezen` | 24/30 |
| Subtitle | `Dagkaart, dagboek en leggingen` | 30/30 |
| Keywords | `tarot,orakel,betekenis,liefde,keltisch,kruis,grote,arcana,ai,deck,leren,reflectie,kaarten,beginners` | 99/100 |

`ja,nee` dropped (RC2), `beginners` added. `kaarten` kept separately because the name has the compound `Tarotkaarten`.

---

## pt (pt-BR)

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Leitura de Tarô` | 21/30 |
| Subtitle | `Carta do dia, diário, tiragens` | 30/30 |
| Keywords | `tarot,cartas,oráculo,significado,amor,cruz,celta,arcanos,maiores,ia,baralho,aprender,iniciantes` | 95/100 |

pt-BR spelling (Tarô in the name, `tarot` as keyword for the international spelling). `sim,não` dropped (RC2), `iniciantes` added.

---

## tr

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Tarot Falı` | 16/30 |
| Subtitle | `Günün kartı, günlük, açılımlar` | 30/30 |
| Keywords | `kartları,anlamları,aşk,kelt,haçı,büyük,arkana,yapay,zeka,deste,öğren,yansıma,başlangıç` | 86/100 |

Falı is the normal genre noun (allowed). `tarot` dropped (in name), `evet,hayır` dropped (RC2), `başlangıç` added.

---

## uk

| Field | Value | Chars |
|---|---|---|
| Name | `Taro: Карти Таро` | 16/30 |
| Subtitle | `Карта дня, щоденник і розклади` | 30/30 |
| Keywords | `ворожіння,значення,кохання,кельтський,хрест,старші,аркани,ші,оракул,колода,tarot,навчання` | 89/100 |

`таро` dropped (in name), `так,ні` dropped (RC2); Latin `tarot` kept for mixed-script queries; `навчання` added.
