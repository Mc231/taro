# Arabic and Japanese samples: Today (S05) and Reading (S09)

Key strings for the `ar` (RTL) and `ja` (CJK) design passes. The `ar` column matches the existing artboards [`TodayAr.dc.html`](../screens/TodayAr.dc.html) and [`ReadingAr.dc.html`](../screens/ReadingAr.dc.html) where they overlap; the rest is new. `ja` has no artboard yet. These strings let designers build `ja` frames and let the goldens in 06 (en, ar, de, ja) run before the reviewed ARB files exist.

Status: draft translations for layout testing. Register: `ar` uses Modern Standard Arabic, `ja` the polite form (03 §9.2 `style.<locale>.md`). Card names follow the traditional names per locale (01 §11 step 2) but are **provisional** until `glossary.yaml` is reviewed. Compliance strings (`disclaimerShort`, `aiLabel`, `reportReadingTitle`) are owned by 05 §3 and need native review before release.

ARB keys marked with † are suggestions (they are not fixed in GLOSSARY or 05 yet).

## Today (S05)

| ARB key | en | ar | ja |
|---|---|---|---|
| (date, `intl` `MMMMEEEEd`) | Saturday, 27 September | السبت، ٢٧ سبتمبر | 9月27日(土) |
| `homeGreetingMorning` † | Good morning | صباح الخير | おはようございます |
| `homeGreetingAfternoon` † | Good afternoon | نهارك سعيد | こんにちは |
| `homeGreetingEvening` † | Good evening | مساء الخير | こんばんは |
| `balanceChipFree` † | 1 free reading | قراءة مجانية واحدة | 無料リーディング 1回 |
| `balanceChipFreeUsed` † | Free reading used · 3 readings | استُخدمت القراءة المجانية · ٣ قراءات | 無料分は使用済み・残り3回 |
| `balanceChipEmpty` † | Free reading used | استُخدمت القراءة المجانية | 無料分は使用済み |
| `nextFreeIn` † | Next free reading in 5 h 12 min | القراءة المجانية التالية بعد ٥ ساعات و١٢ دقيقة | 次の無料リーディングまで 5時間12分 |
| `readingsUnavailableDevice` † | Readings unavailable on this device | القراءات غير متاحة على هذا الجهاز | この端末ではリーディングを利用できません |
| `dailyCardOverline` † | YOUR DAILY CARD | بطاقتك اليومية | 今日のカード |
| `dailyCardTileTitle` † | One card to sit with today | بطاقة واحدة تتأمّلها اليوم | 今日じっくり向き合う1枚 |
| `dailyCardTileBody` † | Free, works offline, no AI. | مجانية، وتعمل دون اتصال، وبلا ذكاء اصطناعي. | 無料・オフライン対応・AIは使いません。 |
| `dailyCardReveal` † | Reveal card | اكشف البطاقة | カードをめくる |
| `homeReadingCtaTitle` † | Ask the cards a question | اطرح سؤالًا على البطاقات | カードに問いかける |
| `homeReadingCtaBody` † | Pick a spread, draw your cards and get a reading that looks at how they relate. | اختر توزيعة، واسحب بطاقاتك، واحصل على قراءة تتأمّل كيف ترتبط البطاقات ببعضها. | スプレッドを選んでカードを引くと、カード同士のつながりを読み解くリーディングが届きます。 |
| `startReading` † | Start a reading | ابدأ قراءة | リーディングを始める |
| `homeRecent` † | Recent | الأحدث | 最近のリーディング |
| (recent row meta) | Past · Present · Future · Yesterday | الماضي · الحاضر · المستقبل · أمس | 過去・現在・未来・昨日 |
| `firstRunCoachmark` † | Start here: your first reading is free today. | ابدأ من هنا: قراءتك الأولى مجانية اليوم. | ここから始めましょう。今日の最初のリーディングは無料です。 |
| `tabToday` † | Today | اليوم | 今日 |
| `tabJournal` † | Journal | اليوميات | ジャーナル |
| `tabLearn` † | Learn | تعلّم | 学ぶ |
| `tabSettings` † | Settings | الإعدادات | 設定 |

Plural (01 §13, ICU), `readingsCount` †:
- en: `{count, plural, one{1 reading} other{{count} readings}}`
- ar: `{count, plural, zero{لا قراءات} one{قراءة واحدة} two{قراءتان} few{{count} قراءات} many{{count} قراءة} other{{count} قراءة}}`
- ja: `{count}回` (no plural forms)

## Reading (S09)

| ARB key / field | en | ar | ja |
|---|---|---|---|
| `done` † (a11y label) | Done | تم | 完了 |
| `addNote` † | Add note | إضافة ملاحظة | メモを追加 |
| `more` † (a11y label) | More | المزيد | その他 |
| `spread_three_ppf_pos_past_name` | Past | الماضي | 過去 |
| `spread_three_ppf_pos_present_name` | Present | الحاضر | 現在 |
| `spread_three_ppf_pos_future_name` | Future | المستقبل | 未来 |
| `orientationUpright` † | Upright | معتدلة | 正位置 |
| `orientationReversed` † (badge + text label, 01 §12) | Reversed | مقلوبة | 逆位置 |
| card `cups_03` (provisional) | Three of Cups | ثلاثة الكؤوس | カップの3 |
| card `major_17` (provisional) | The Star | النجمة | 星 |
| card `pentacles_08` (provisional) | Eight of Pentacles | ثمانية العملات | ペンタクルの8 |
| question (user text) | “How can I rebuild after a hard year at work?” | «كيف أبدأ من جديد بعد عام صعب في العمل؟» | 「大変だった仕事の一年から、どう立て直せばいいですか？」 |
| `reading.title` (AI) | A season of rebuilding | موسم لإعادة البناء | 立て直しの季節 |
| `reading.overview` (AI) | The cards move from shared joy, through a dimmed sense of hope, toward patient, skilled work. They suggest the rebuilding may come less from a single turning point and more from steady practice. | تنتقل البطاقات من فرحٍ مشترك، مرورًا بأملٍ خَفَت بريقه، نحو عملٍ صبور ومتقن. وتوحي بأن إعادة البناء قد لا تأتي من نقطة تحوّل واحدة بقدر ما تأتي من ممارسة ثابتة يومًا بعد يوم. | カードは、分かち合う喜びから、少し陰った希望を経て、根気強く丁寧な仕事へと移っていきます。立て直しは一度の転機よりも、日々の積み重ねから生まれるのかもしれません。 |
| position heading (pattern `{position} · {card}, {orientation}`) | Present · The Star, reversed | الحاضر · النجمة، مقلوبة | 現在・星（逆位置） |
| `cards[present].interpretation` (AI) | Reversed, the Star can point to hope that feels far away right now. You might consider what small, dependable sources of energy are still within reach. | حين تظهر النجمة مقلوبة، قد تشير إلى أملٍ يبدو بعيدًا في الوقت الحالي. ربما يفيدك أن تتأمّل مصادر الطاقة الصغيرة الموثوقة التي ما زالت في متناولك. | 逆位置の星は、今は希望が遠く感じられることを示しているのかもしれません。小さくても頼りになるエネルギー源が、まだ手の届くところにないか考えてみてください。 |
| `aiLabel` (05 §3) | AI-generated | من إنتاج الذكاء الاصطناعي | AI生成 |
| `readingSynthesis` † | How the cards connect | كيف ترتبط البطاقات | カード同士のつながり |
| `readingReflectionPrompts` † | Questions to reflect on | أسئلة للتأمّل | 振り返りのための問い |
| `writeAboutThis` † | Write about this | اكتب عن هذا | これについて書く |
| `favourite` † | Favourite | المفضّلة | お気に入り |
| `share` † | Share | مشاركة | 共有 |
| `ratingReasonTooGeneric` † | Too generic | عامة جدًا | ありきたりすぎる |
| `ratingReasonMismatch` † | Didn't match the cards | لا تطابق البطاقات | カードと合っていない |
| `ratingReasonTone` † | Tone | الأسلوب | 口調 |
| `ratingReasonOther` † | Other | أخرى | その他 |
| `reportReadingTitle` (05 §3) | Report this reading | الإبلاغ عن هذه القراءة | このリーディングを報告 |
| `readingReadyAnnouncement` † (live region) | Reading ready | القراءة جاهزة | リーディングの準備ができました |
| `disclaimerShort` (05 §3) | For entertainment and self-reflection. Not professional advice. | للترفيه والتأمّل الذاتي. ليست نصيحة مهنية. | エンターテインメントと自己省察のためのものです。専門的な助言ではありません。 |
| `readFullDisclaimer` † | Read the full disclaimer | اقرأ إخلاء المسؤولية كاملًا | 免責事項をすべて読む |
| screen reader card label (01 §12) | Three of Cups, reversed, position: Past | ثلاثة الكؤوس، مقلوبة، الموضع: الماضي | カップの3、逆位置、位置：過去 |

## Layout notes

**Arabic (RTL, 01 §13)**
- Full mirroring through `Directionality`: the balance chip moves left, the tab order is reversed, and the Past card sits on the **right** of the spread row. Card art and Roman numerals are never mirrored; the canvas sets `dir="ltr"` on the card face and `dir="rtl"` on the name inside it.
- Digits: `intl` ar defaults render Arabic-Indic digits (٢٧, ٣, ٥), as on the canvas. Prices come from the store as-is.
- Separators: `·` stays between RTL runs; the question is quoted with «». Mixed LTR fragments (a Support ID, file names, phone numbers) are bidi-isolated.
- Fonts: IBM Plex Sans Arabic (UI) and Noto Serif Arabic (reading/title fallback), both bundled. Arabic needs ~10–15% more line height than Latin at the same size; `type.bodyReading` keeps line height ≥ 1.5, and the canvas uses serif 17/26 for the ar reading body.
- The ar reading text on the canvas is about 1.1× the English length. It wraps; check 200% scale in `ReadingLargeText`.

**Japanese (CJK)**
- There is no ja artboard yet. Duplicate `Today` / `Reading` with the `ja` strings and the IBM Plex Sans JP / Noto Serif JP fonts.
- Line breaking: no spaces, so wrapping relies on the CJK line-break rules (no line starts with `、。）」`). Keep keyword chips and buttons on one line; titles may wrap anywhere.
- Separators: use the full-width `・` instead of ` · `; brackets `（）` and quotes `「」` are full-width.
- Japanese strings are usually **shorter** in characters but wider per glyph. Check the tab label "ジャーナル" and the chip "無料分は使用済み・残り3回" at 12–14 sp.
- The orientation terms 正位置 / 逆位置 are the standard tarot vocabulary; "Reversed" must still appear as text next to the rotation (01 §12).
