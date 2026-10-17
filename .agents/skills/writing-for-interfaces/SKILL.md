---
name: writing-for-interfaces
description: >
  Use when someone asks to write, rewrite, review, or improve text that appears inside a
  product or interface. Examples: "review the UX copy", "is there a better way to phrase
  this", "rewrite this error message", "write copy for this screen/flow/page", reviewing
  button labels, improving CLI output messages, writing onboarding copy, settings
  descriptions, or confirmation dialogs. Trigger whenever the request involves wording shown
  to end users inside software — apps, web, CLI, email notifications, modals, tooltips,
  empty states, or alerts. Also trigger for vague requests like "review the UX" where
  interface copy review is implied. Do NOT trigger for content marketing, blog posts, app
  store listings, API docs, brand guides, cover letters, or interview questions — this is a
  technical writing skill for interface language.
---

# Writing for Interfaces

Good interface writing is invisible. When words work seamlessly with design, people don't
notice them.

Writing should be part of the design process from the start, not something filled in at the
end. When words are considered alongside layout, interaction, and visual design, the result
feels seamless. When they're an afterthought, product experiences feel stitched together.

Every piece of text in an interface is a small act of communication: it should respect the
person's time, meet them where they are, and help them move forward.

---

## When triggered

### Step 1: Establish voice and personality

Voice is the foundation. All copy decisions — what to say, how to say it, what to leave
out — flow from a clear understanding of who this product is, who it's for, and how it
should sound. Without a defined voice, copy becomes inconsistent and the product loses coherency.

**Search for an existing voice definition.** Check for:

- A `CLAUDE.md`, `AGENTS.md`, or similar project config that defines voice and/or tone
- A style guide, design system documentation, or brand guidelines
- A word list or terminology reference

**If a voice definition exists**, use it as the lens for all copy work. If the copy you're
working on drifts from it, flag the inconsistency.

**If no voice definition exists**, infer the current voice from existing copy. Look for
patterns: formal or casual? Technical or plain? Warm or matter-of-fact? If the copy is
inconsistent or insufficient to infer from, help the user establish a voice before writing.

#### Establishing voice through conversation

Walk the user through these questions:

1. **What does the product do and who is it for?** A banking app for professionals and a
   savings app for kids serve similar purposes but should sound completely different. The
   audience determines vocabulary, complexity, and register.

2. **Why do people use it, and where?** Someone using a health app during a crisis needs
   calm clarity. Someone browsing a game at home can handle playfulness. The context of use
   — physical environment, emotional state, competing attention — shapes how much text
   people can absorb and what tone is appropriate.

3. **Imagine the product as a person. What 3–4 personality traits make them unique?**
   Brainstorm freely, group similar words into themes, discard table-stakes traits ("not
   confusing"), and keep the ones that genuinely differentiate the product's personality.

4. **Look for productive tensions.** The best voice definitions have qualities that push
   against each other. "Friendly" and "concise" create a useful tension — these become the
   dials you turn when adjusting tone for different situations.

5. **Capture it.** Suggest the user persist the voice definition somewhere durable
   (`AGENTS.md`, `CLAUDE.md` or style guide document) so it persists across sessions. A word list pairs well with this and should be stored in the same file.

### Step 2: Evaluate the request

Identify what kind of copy work is needed:

- **New copy**: Writing from scratch for a screen, flow, or component.
- **Review**: Evaluating existing copy for clarity, consistency, and tone.
- **Rewrite**: Improving specific text that isn't working.
- **Terminology**: Building or maintaining a word list.

Then identify which interface patterns are involved
and consult `references/patterns.md` for the relevant sections.

### Step 3: Apply voice, then principles

For every piece of copy, work in this order:

1. **Does it sound like the voice?** Read it against the 3–4 qualities. If you read it
   aloud, would you recognise it as coming from this product?
2. **Which qualities need dialing up or down for this situation?** Think of each voice
   quality as a dial. A celebratory moment turns up warmth; an error turns up clarity and
   dials back friendliness.
3. **Apply the core principles** (purpose, anticipation, context, empathy — detailed below).
4. **Apply the craft rules** (remove filler, avoid repetition, be specific — detailed below).

The ordering is deliberate and encodes a precedence chain: **clarity > voice > craft
rules.** Clarity always wins — if voice gets in the way of someone understanding what to
do, strip it back. Voice comes next — it shapes how things sound, and a craft rule should
never cut a word or restructure a phrase in a way that undermines the established voice.
Craft rules are voice-filtered heuristics, not absolutes. Always cross-check craft edits
against the voice before committing them.

### Step 4: Deliver changes

Work through the copy element by element — title, body, buttons, labels — showing the
original, then the rewrite, with a brief rationale tied to voice and principles. Prioritise
changes that confuse or block users before polish. When reviewing across a flow, flag
terminology inconsistencies and suggest word list entries at the end.

---

## Voice and tone

### Voice vs. tone

**Voice** is the consistent personality of the product — the 3–4 qualities that define how
it always sounds. These don't change.

**Tone** is how the voice adapts to the situation. Think of each voice quality as a dial you
can turn up or down depending on the moment:

- Celebrating a milestone? Turn up warmth, dial back brevity.
- Reporting an error? Turn up clarity and helpfulness, dial back friendliness.
- Onboarding a new user? Balance helpfulness with warmth.
- Confirming a destructive action? Turn up directness, keep calm and concise.

### Applying tone in practice

For each situation, decide which voice qualities need emphasis and which should recede.

**Example**: For an error where someone can't connect to the network, clarity and
helpfulness go way up. Simplicity stays moderate because they need the most important
details. Friendliness dials back because getting them unstuck matters more than sounding
warm.

### Where personality belongs

Personality shines in moments where there's room for it — welcome screens, milestones,
empty states. In error messages, destructive actions, and critical flows, dial voice back
and let clarity lead. The precedence chain from Step 3 applies: clarity first, always.

---

## Core principles

Purpose, Anticipation, Context, Empathy — a framework for what to write, how to write it,
and when. Apply through the lens of your voice.

### 1. Purpose

Before writing, answer: **what is the single most important thing the person needs to know
right now?**

- **Use information hierarchy.** Headlines and buttons carry the primary message; supporting
  text fills in detail. If someone reads only headers and buttons, they should understand
  the situation.
- **Cut what doesn't serve this moment.** Move it elsewhere or remove it. When a screen
  tries to do too much, return to its purpose and strip away everything else.
- **Tell people the purpose.** When introducing a feature, tell them why it exists and why
  it matters to them.

### 2. Anticipation

Think of the interface as a conversation. In any good conversation there's a natural back
and forth — listening, responding, anticipating what the other person needs to hear next.

- After telling someone about a problem, tell them how to fix it. "Can't connect to
  Wi-Fi" → "Can't connect to Wi-Fi. Check your connection and try again."
- After asking someone to do something, make it obvious how to do it. "Verify your
  identity" → "Verify your identity" with a clear button or link to start the process.
- After someone completes something, acknowledge it and point forward. "Password changed"
  → "Password changed. You can now sign in with your new password."
- **Lead with the "why".** Put the benefit or reason before the instruction: "To [benefit],
  [instruction]." Front-loading motivation makes the instruction feel like a reasonable ask
  instead of a demand.

### 3. Context

People use products in wildly different circumstances. The usage context shapes the writing.

- **Think outside the app.** Consider the physical and emotional situation.
- **Match density to available attention.** Mid-task text should be ultra-brief. Setup flows
  can afford more.
- **Timing matters.** Show information when it's relevant, not before. Place instructions
  where the person is looking.
- **Write for the device.** Describe gestures correctly ("tap" not "click" on touch). Phones
  demand brevity; shared screens (TVs) need large, scannable text.

### 4. Empathy

Write for everyone who might use this product — different abilities, languages, cultures,
technical fluency, and emotional states.

- **Use plain, direct language.** Avoid jargon, idioms, and culturally specific references.
- **Design for accessibility from the start.** Labels, descriptions, and alt text aren't
  afterthoughts — they're the entire experience for some people. See patterns reference for
  detailed guidance.
- **Use inclusive, neutral language.** Avoid unnecessary references to gender, age, or
  ability.
- **Consider localisation.** Write short copy, not compressed long copy. Account for text
  expansion and RTL languages.

---

## Writing craft

Practical editing moves that tighten copy. Apply after confirming voice and tone are right.

### Remove filler words

Interface text has no minimum word count. Every word must earn its place. But before cutting
a word, check whether it's doing voice work. A word that's "filler" by general craft rules
may be load-bearing for the voice — "yet" in "Nothing here yet" carries warmth and calm,
and removing it makes the empty state blunter. **The test:** remove the word; if neither
meaning nor intentional tone changes, cut it.

- **Adverbs/adjectives**: "Simply enter your license plate" → "Enter your license plate."
  Words like "simply," "quickly," "easily," "just," "successfully" often promise something
  you can't guarantee. Keep words that genuinely clarify ("Feed your pets automatically").
- **Interjections**: "Oops!", "Uh oh!" in errors trivialise the problem. Cut them.
- **Pleasantries**: "Sorry" and "please" sound insincere in automated messages. Use only
  when they genuinely add warmth.
- **Punctuation**:
  - **Exclamation marks**: rare. Reserve for genuinely celebratory moments.
  - **Dashes** (en/em): avoid in interface copy. They interrupt scanning. Break into
    separate lines or sentences instead.
  - **Ellipsis**: only for processes in progress ("Loading..."), not trailing thoughts.

### Avoid repetition

Combine overlapping ideas into one clear statement. Each element on screen should add new
information. When headline and body say the same thing in different words, collapse them.

"We're running late. Your delivery driver won't make it on time. They'll be there in 10
minutes." → "Delivery delayed 10 minutes. Check the app for your driver's location."

### Be specific, not vague

- Name the thing: "Can't open 'Quarterly Report.pdf'" not "Can't open this file."
- Name the action: "Cancel Subscription" / "Keep Subscription" not "Yes" / "No."
- Give real information: "Your card ending in 4242 was declined" not "There was a payment
  error."

### Keep a word list

Decide what you call things and stick to it. If it's "alias" on one screen, don't use
"username" on another. A word list is a simple table: **Use** / **Don't use** /
**Definition**. Button labels are especially good entries — if "Next" advances through a
flow, use "Next" everywhere.

### Pronouns and perspective

"Favorites" conveys the same message as "Your Favorites." Avoid "we" — it obscures what
actually happened ("We're having trouble..." → "Unable to load content").

### Sweat the details

Correct spelling, grammar, and punctuation build trust. Adopt capitalisation rules aligned
with the voice (title case = formal, sentence case = casual) and apply consistently. Write
for the space available — if copy needs to be short, write a short sentence, don't compress
a long one.

### Write for dynamic content

Templated strings (`"${count} items selected"`) are interface copy too. Write them so every
possible output reads naturally:

- **Handle zero, one, and many.** "No results," "1 result," "24 results" — not a single
  template that produces "0 results found."
- **Read it with real values.** Substitute short and long names, small and large numbers.
  "Welcome back, Christopher-Montgomery!" might break layout; "3 seconds ago" and "2 days
  ago" should both read naturally.
- **Keep templates simple.** If a string needs complex branching to read well, the design
  may be asking too much of a single element.

### Build language patterns

Define patterns for common moments — how flows begin ("Get Started"), advance ("Next" or
"Continue" — pick one), and end ("Done"). Use them consistently.

---

## The simplest test

Read your writing out loud. If it sounds like how you'd explain something to a friend —
clear, natural, no filler — it's probably good. If it sounds like a robot, a legal
document, or an essay, keep refining.

---

## Patterns reference

For detailed guidance on alerts, errors, empty states, onboarding, notifications,
accessibility labels, destructive actions, buttons, and instructional copy — see
`references/patterns.md`.
