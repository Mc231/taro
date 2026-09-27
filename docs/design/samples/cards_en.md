# Sample card texts (en), 5 cards

Real-length English content for the design sessions (Phase 14 Sprint 14.1): the daily card (S13), card detail (S17), the reveal captions (S08), the Classic reading (S32) and the Journal (S14/S15). Each block follows the `CardText` shape of `01_PRODUCT.md` §10.1, as it will appear in `packages/taro_content/source/en/cards/{cardId}.yaml`, and stays within the §10.1 length bounds:

| Field | Bound (01 §10.1) |
|---|---|
| `keywordsUpright` / `keywordsReversed` | 3–6 items, each ≤ 24 chars |
| `shortUpright` / `shortReversed` | ≤ 160 chars |
| `meaningUpright` | 120–220 words |
| `meaningReversed` | 100–200 words |
| `aspects.*.upright` / `.reversed` | 40–90 words each (relationships, work, growth) |
| `reflectionQuestions` | exactly 3, each ≤ 120 chars |
| `imageryNote` | 40–100 words, describes Taro's original art (D15), not any published deck |

Voice (01 §11 style guide): reflection, not prediction. We use "may", "can" and "invites", never "will happen". There are no health, legal or money claims, "you" is gender-neutral, and there is no Markdown inside the values. Names come from GLOSSARY §1. `sourceHash` and `reviewStatus` are omitted here (they are written by `tools/content`).

The designs use the first three keywords. S13 and S17 show `shortUpright`, the full meaning, and one reflection question. S32 shows the short text + the meaning under each position.

---

## The Star (`major_17`)

```yaml
cardId: major_17
name: The Star
keywordsUpright: [Hope, Renewal, Quiet faith, Openness, Rest after strain]
keywordsReversed: [Discouragement, Depletion, Lost direction, Self-doubt]
shortUpright: After a storm, the Star invites you to rest and let things refill slowly. Hope here is gentle and practical, not a leap.
shortReversed: Reversed, the Star can reflect hope that feels far away. It may ask what small, dependable things still give you energy.
meaningUpright: >-
  The Star arrives after the upheaval of the Tower in the Major Arcana, and it
  carries the feeling of a clear night once a storm has passed. Nothing is
  rebuilt yet, but the air is calm enough to breathe. A figure kneels by the
  water, pouring from two jugs: one back into the pool, one onto the land. The
  image suggests giving and receiving at an unhurried pace, letting what has
  been drained fill up again. In a reading, the Star can point to a period of
  quiet recovery, when hope feels less like a big promise and more like a small
  light you can steer by. It may invite you to be honest and unguarded, to let
  others see where you are, and to trust that slow, steady care counts. The
  Star does not ask for grand plans. It asks what helps you feel like yourself
  again, and whether you can give that a little room each day. Many people read
  it as a reminder that openness and patience are strengths, especially after
  a hard stretch.
meaningReversed: >-
  Reversed, the Star can reflect a moment when hope feels thin or out of reach.
  You may be tired in a way that sleep alone does not fix, or unsure whether
  your efforts are adding up to anything. The water in the image is still
  there; it may simply be harder to notice. This position often invites a
  gentler question than "what is wrong with me?": what has been drawing energy
  away, and what small, reliable sources of it are still within reach? It can
  also point to hiding your needs or telling yourself they do not matter. The
  reversed Star is not a verdict. It is an invitation to lower the bar for a
  while, to look for one or two things that restore you, and to let other
  people help carry the jug.
aspects:
  relationships:
    upright: >-
      In relationships, the Star can reflect a softer, more hopeful phase after
      tension or distance. It may invite you to show up without armour, to say
      what you would like instead of what you fear, and to let trust rebuild
      through small, repeated gestures rather than one big conversation.
    reversed: >-
      Reversed, it may point to feeling unseen or to hoping less than you used
      to. You might ask whether you have stopped sharing what you need. A quiet,
      honest request can matter more than waiting for the other person to
      notice on their own.
  work:
    upright: >-
      At work, the Star often suggests renewed motivation after a draining
      period. It can favour work that feels meaningful over work that only looks
      impressive. You might consider which tasks give you a sense of purpose,
      and how to protect a little time for them each week.
    reversed: >-
      Reversed, it can mirror burnout or the sense that effort is not being
      rewarded. It may be worth separating what you can change from what you
      cannot, and asking for support before the tank runs completely empty.
      Naming the strain out loud is often the first step to easing it.
  growth:
    upright: >-
      For personal growth, the Star invites steady self-care that is practical
      rather than dramatic: sleep, time outside, a routine that refills you. It
      can also reflect a renewed connection to your values and to a quieter
      kind of confidence. Hope, here, is something you practise in small ways
      rather than something you wait for.
    reversed: >-
      Reversed, it may ask where you have lost touch with what matters to you.
      Rather than forcing optimism, it can help to notice one small thing each
      day that felt good, and to let that be enough for now. Being patient with
      yourself is part of the work.
reflectionQuestions:
  - What small thing helps you feel restored today?
  - Where could you let someone see what you really need?
  - What would a slower, kinder pace look like this week?
imageryNote: >-
  In Taro's art, a figure kneels at the edge of a still pool under a deep blue
  sky, pouring water from two ochre jugs, one into the pool and one onto the
  earth. A large eight-pointed star shines above, with seven smaller stars
  around it. A small bird rests on a nearby tree, a quiet sign of calm returning.
```

---

## Three of Cups (`cups_03`)

```yaml
cardId: cups_03
name: Three of Cups
keywordsUpright: [Celebration, Friendship, Belonging, Shared joy]
keywordsReversed: [Feeling left out, Social fatigue, Overindulgence, Gossip]
shortUpright: Three friends raise their cups. The card points to joy that grows when it is shared, and to the people who help you feel at home.
shortReversed: Reversed, it can reflect feeling left out, or a social rhythm that has become tiring. It may invite smaller, truer gatherings.
meaningUpright: >-
  The Three of Cups shows three people raising their cups together, often in a
  garden or at harvest time. It is one of the warmest cards in the Cups suit,
  which is linked to feelings and relationships. Here the focus is less on one
  close bond and more on community: friends, a team, a family that chose each
  other. In a reading, the card can point to something worth celebrating, even
  if it is small, and to the value of marking it with other people. It may
  also reflect a time when support comes from a circle rather than a single
  person. You might ask who makes you feel at home, and whether you have let
  them know. The card can also invite you to receive joy, not only to organise
  it for others. Its message is simple and generous: good moments deepen when
  they are shared, and belonging is built in ordinary evenings as much as in
  big occasions.
meaningReversed: >-
  Reversed, the Three of Cups can reflect a social life that feels out of tune.
  You may feel left out of a group, or you may be the one who keeps saying yes
  to gatherings that leave you drained. It can also point to celebration that
  has tipped into excess, or to talk behind someone's back that spoils the
  warmth of a group. The card does not ask you to withdraw. It may invite you
  to notice which connections feel nourishing and which feel like obligation,
  and to choose a few that are true. Sometimes the reversed card simply asks
  for a quieter season: fewer people, more honesty, and room to rest.
aspects:
  relationships:
    upright: >-
      In relationships, the card can point to warmth that is supported by a
      wider circle. Friends who like you both, shared traditions and time with
      others may strengthen your closest bond. It may invite you to celebrate
      each other openly, and to make room for the friends and family who
      cheer you on.
    reversed: >-
      Reversed, it can reflect a third person or a group dynamic that creates
      tension, or the feeling that you are more connected to others than to each
      other. You might ask what you would like more of when it is just the two
      of you. Protecting some time that belongs only to the two of you can
      restore the balance.
  work:
    upright: >-
      At work, the Three of Cups often suggests a team win worth pausing to mark
      together. Shared credit and simple rituals of appreciation can make a
      group stronger. It may also favour collaboration over going it alone on a
      current project.
    reversed: >-
      Reversed, it may mirror office cliques, gossip, or a team that socialises
      well but struggles to finish things. It can help to name what the group is
      for, and to include people who have been quietly left out. A small
      gesture of recognition can reset the mood.
  growth:
    upright: >-
      For personal growth, the card invites you to let yourself be celebrated,
      not only helpful. Receiving praise, joining in and accepting care are
      skills too. You might notice which people help you feel most like
      yourself, and seek out a little more time with them.
    reversed: >-
      Reversed, it may ask whether you are keeping busy socially to avoid
      something quieter. Time alone can be restful rather than lonely. It may be
      worth asking which gatherings you look forward to and which you only
      endure, and to give yourself permission to skip the rest.
reflectionQuestions:
  - Who helps you feel at home, and when did you last tell them?
  - What small win could you celebrate this week?
  - Which gatherings leave you lighter, and which leave you tired?
imageryNote: >-
  Taro's Three of Cups shows three figures in a circle among late-summer fruit,
  their golden cups lifted to meet in the middle. Their clothes echo the three
  colours of the suit's border. The ground is full of gourds and grapes, a sign
  of abundance, and the figures lean toward each other as if caught mid-laugh.
```

---

## Eight of Pentacles (`pentacles_08`)

```yaml
cardId: pentacles_08
name: Eight of Pentacles
keywordsUpright: [Craft, Practice, Diligence, Skill-building, Focus]
keywordsReversed: [Perfectionism, Going through motions, Scattered effort, Burnout]
shortUpright: A maker works on one coin after another. The card honours steady practice and the quiet pride of getting better at something.
shortReversed: Reversed, it can reflect effort without direction, or perfectionism that makes the work feel heavy. It may ask what you are practising for.
meaningUpright: >-
  The Eight of Pentacles shows a craftsperson at a bench, carving the same
  symbol into coin after coin. Several finished pieces hang nearby, and more
  wait to be made. Pentacles is the suit of the practical world: work, skills,
  the body and resources. This card is about apprenticeship in the widest
  sense, the patient repetition through which anyone becomes good at
  something. In a reading, it can point to a season of focused practice, study
  or careful work, when progress comes from showing up rather than from a big
  breakthrough. It may invite you to take pride in the details, to protect time
  for deep work, and to accept being a beginner for a while. The card can also
  reflect satisfaction in work done well for its own sake. You might ask which
  skill you would like to grow, and what a small, repeatable step toward it
  could be.
meaningReversed: >-
  Reversed, the Eight of Pentacles can reflect work that has lost its sense of
  purpose. You may be busy without feeling that you are improving, or you may
  be polishing one piece endlessly because it never feels good enough. It can
  also point to cutting corners out of tiredness, or to spreading effort
  across too many things at once. The card may invite you to step back and ask
  what you are practising for, and whether the pace is sustainable. Sometimes
  the reversed card asks for rest before more effort; sometimes it asks you to
  choose one thing and let the rest wait.
aspects:
  relationships:
    upright: >-
      In relationships, the card can point to love expressed through steady
      effort: showing up, learning each other's habits, doing the small
      practical things well. It may invite you to treat the relationship as
      something you build together over time, the way a skill grows with
      practice and attention.
    reversed: >-
      Reversed, it may reflect a relationship that is running on routine, or one
      partner putting work ahead of connection. You might ask what attention the
      relationship needs that a busy schedule has pushed aside. Even one unhurried evening together can remind you both
      why the effort is worth it.
  work:
    upright: >-
      At work, the Eight of Pentacles often suggests skill-building, training
      or a project that rewards care and precision. It can favour deep focus and
      learning from people with more experience. Quality may matter more than
      speed right now, and small improvements may be noticed more than you
      expect.
    reversed: >-
      Reversed, it can mirror repetitive work with no growth, or perfectionism
      that delays finishing. It may be worth asking for feedback, setting a
      clear definition of "done", and noticing whether the work still teaches
      you anything. A short break can bring back the care the work deserves.
  growth:
    upright: >-
      For personal growth, the card invites patient practice of something that
      matters to you, whether it is a craft, a language or a habit. Small,
      regular sessions can add up to real change. It may help to track progress so that you can see how far
      you have come.
    reversed: >-
      Reversed, it may ask whether you are judging yourself by output alone.
      Rest, play and learning without a goal can restore the curiosity that
      made practice enjoyable in the first place. You are more than what you
      produce, and your worth does not depend on the next result.
reflectionQuestions:
  - Which skill would you like to grow a little this month?
  - What does "good enough" look like for the task in front of you?
  - Where could a small, regular practice replace a big push?
imageryNote: >-
  In Taro's art, a young maker sits at a wooden bench in soft morning light,
  hammer and chisel in hand, shaping a golden coin. Six finished coins hang on
  a post beside them, and one more lies at their feet, waiting. A village sits
  in the distance, suggesting that the work is private but connected to a
  wider community.
```

---

## Two of Swords (`swords_02`)

```yaml
cardId: swords_02
name: Two of Swords
keywordsUpright: [Stalemate, Hard choice, Avoidance, Guarded calm]
keywordsReversed: [Indecision easing, Information arriving, Overwhelm, Releasing a block]
shortUpright: A blindfolded figure balances two crossed swords. The card reflects a choice you may be holding off, and the calm it costs to keep it there.
shortReversed: Reversed, the Two of Swords can point to a stuck choice starting to shift. What you have been weighing may be harder to set aside now.
meaningUpright: >-
  The Two of Swords shows a figure sitting by the water at night, blindfolded,
  with two swords crossed over the heart. Swords is the suit of the mind:
  thoughts, words, decisions and conflict. Here the mind is holding perfectly
  still. In a reading, the card can reflect a decision you are postponing, or
  two options that seem equally hard to choose between. The blindfold may point
  to information you have not looked at yet, or to feelings you are keeping out
  of the picture so that you can stay calm. That calm is real, but it takes
  effort to maintain. The card does not push you to decide quickly. It may
  invite you to lower the swords a little: to gather what you need to know,
  to notice what your body and feelings are telling you, and to ask whether
  not choosing has become a choice of its own.
meaningReversed: >-
  Reversed, the Two of Swords can point to a stalemate that is beginning to
  shift. New information may be arriving, or the effort of holding everything
  in balance may have become too tiring to keep up. This can feel like relief,
  or like being overwhelmed by too many thoughts at once. The card may invite
  you to take the blindfold off gently: to look at one part of the situation at
  a time, and to talk it through with someone you trust. It can also reflect
  the release of a long-held tension, when a decision you have been weighing
  finally feels possible to make.
aspects:
  relationships:
    upright: >-
      In relationships, the card can reflect a truce or an avoided conversation.
      Things may seem peaceful because a difficult topic is being held at
      arm's length. It may invite you to consider what you both know but have
      not yet said.
    reversed: >-
      Reversed, it may point to that conversation becoming harder to avoid, or
      to one of you finally naming what has been unspoken. Going slowly and
      listening fully can matter as much as reaching an answer, and kindness
      helps both of you stay open.
  work:
    upright: >-
      At work, the Two of Swords often suggests a decision stuck between two
      options, or a conflict you are staying neutral in. You might gather more
      facts, set a date to decide, or ask what you would choose if neither
      option had to be perfect. A clear deadline can turn waiting into
      deciding.
    reversed: >-
      Reversed, it can mirror information overload, or a stalled decision that
      is starting to move because circumstances changed. It may help to write
      the options down and look at them one at a time, and to ask a trusted
      colleague what they notice.
  growth:
    upright: >-
      For personal growth, the card invites curiosity about what you are
      protecting yourself from by staying undecided. Stillness can be wise; it
      can also be a way to avoid feelings that deserve attention. You might ask
      which of the two is true for you right now.
    reversed: >-
      Reversed, it may reflect a readiness to face something you have been
      avoiding. You do not need to resolve everything at once. Naming one true
      thing, to yourself or to someone close, can be enough to begin. The
      rest can follow at its own pace.
reflectionQuestions:
  - What might you see if you looked at this choice without the blindfold?
  - What is staying undecided protecting you from?
  - Who could you talk this through with, honestly and without hurry?
imageryNote: >-
  Taro's Two of Swords shows a seated figure on a stone bench by the sea at
  night, eyes covered with a pale cloth, arms crossed so that two long swords
  rest over the shoulders. A thin crescent moon hangs above calm water dotted
  with small rocks. The pose is balanced and still, and the effort of holding
  it is visible in the tense arms.
```

---

## The Sun (`major_19`)

```yaml
cardId: major_19
name: The Sun
keywordsUpright: [Clarity, Warmth, Confidence, Simple joy, Vitality]
keywordsReversed: [Dimmed joy, Overconfidence, Delayed clarity, Forced cheer]
shortUpright: The Sun suggests openness and simple joy. Things that felt tangled may grow clearer, and you may feel more like yourself.
shortReversed: Reversed, the Sun can reflect joy that feels muted or clouded. It may invite you to notice what still feels warm and true.
meaningUpright: >-
  The Sun is one of the brightest cards in the deck. A child rides a white
  horse under a large, smiling sun, with sunflowers growing behind a garden
  wall. After the uncertain light of the Moon, the Sun brings full daylight:
  things can be seen as they are. In a reading, the card can point to clarity,
  warmth and a sense of being fully yourself. It may reflect a time when
  energy returns, relationships feel easy, or a situation that seemed
  confusing starts to make sense. The Sun is also about simple pleasures:
  playing, being outside, enjoying what is in front of you without needing it
  to mean something bigger. It may invite you to let yourself be seen, to share
  good news and to trust what you know. Its joy is not naive. It is the
  confidence that comes from standing in the light and finding that you are
  still here.
meaningReversed: >-
  Reversed, the Sun can reflect joy that is present but clouded over. You may
  be going through a good period without quite feeling it, or putting on a
  cheerful face while something underneath asks for attention. It can also
  point to overconfidence, when optimism skips over details that matter. The
  card does not take the light away. It may invite you to notice what still
  feels warm and true, to let yourself enjoy small things without waiting for
  everything to be resolved, and to check whether you are being honest with
  yourself about how you really feel. Warmth tends to return when it is
      given a little space.
aspects:
  relationships:
    upright: >-
      In relationships, the Sun can reflect ease, playfulness and openness. It
      may favour honest affection, shared fun and being proud of each other in
      public. You might notice how good it feels to be fully seen by someone,
      and let them know it.
    reversed: >-
      Reversed, it may point to a relationship that looks happy from outside but
      feels flatter inside, or to cheerfulness covering a real concern. A
      light, honest check-in can bring warmth back, especially if you ask
      how the other person is really doing.
  work:
    upright: >-
      At work, the Sun often suggests visibility, recognition and confidence in
      your abilities. It can favour presenting your work, sharing credit and
      bringing enthusiasm to a project that others may join. Letting people
      see your work can open useful doors.
    reversed: >-
      Reversed, it can mirror enthusiasm that outruns planning, or success that
      feels hollow. It may be worth checking the details and asking what would
      make the work feel meaningful again, not only impressive. Clear plans
      can keep good energy from burning out.
  growth:
    upright: >-
      For personal growth, the Sun invites you to reconnect with what makes you
      feel alive and unselfconscious, the way a child plays. Time outdoors,
      movement and laughter can matter more than they seem. Notice what lights
      you up, and give it a place in your week.
    reversed: >-
      Reversed, it may ask where you are waiting for permission to enjoy your
      life. Joy does not have to be earned first. Letting a small pleasure be
      enough can be a quiet kind of courage, and a good place to start.
reflectionQuestions:
  - When did you last feel completely like yourself?
  - What is clearer now than it was a month ago?
  - Which small pleasure could you give more room to this week?
imageryNote: >-
  In Taro's art, a laughing child rides a white horse bareback under a large
  golden sun whose rays alternate straight and wavy. Behind a low stone wall,
  tall sunflowers turn toward the viewer. The child holds a long orange banner
  that curls in the breeze, and the sky is a clear, unbroken blue.
```
