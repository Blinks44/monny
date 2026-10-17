# Interface copy patterns

Detailed guidance for common interface writing situations. Each pattern should be applied
through the lens of your product's voice and tone — the voice stays consistent, the tone
adapts to the situation.

These patterns cover common cases, not every interface element. For anything not listed here,
apply the core principles and voice framework from the main skill document.

## Table of contents

1. [Alerts and dialogs](#alerts-and-dialogs)
2. [Error messages](#error-messages)
3. [Destructive actions](#destructive-actions)
4. [Empty states](#empty-states)
5. [Onboarding and setup flows](#onboarding-and-setup-flows)
6. [Notifications](#notifications)
7. [Accessibility labels](#accessibility-labels)
8. [Buttons and actions](#buttons-and-actions)
9. [Instructional and inline copy](#instructional-and-inline-copy)
10. [Settings and preferences](#settings-and-preferences)

---

## Alerts and dialogs

Alerts interrupt what someone is doing. Every alert must justify that cost by delivering
information the person genuinely needs right now.

### When to use an alert

- To confirm a significant or irreversible action.
- To request access to sensitive data (location, contacts, camera).
- To report an error that blocks progress.
- To notify of an event or situation requiring immediate attention.

### When NOT to use an alert

- For non-essential information (use inline messaging or banners).
- For lengthy content or complex choices (use a dedicated screen).
- For problems you could have prevented (validate input inline).
- For technical diagnostics the person can't act on.
- For common, undoable actions — even destructive ones. People who delete an email intend
  to discard it and can undo the action; they don't need an alert every time.
- At app launch. If something's wrong at startup (like no network), show cached or
  placeholder data with a nonintrusive label describing the problem.

### Structure

A good alert answers: **What happened? Why? What now?**

- **Title**: The main point in one short sentence. If someone reads only the title and
  buttons, they should understand the situation. Sentence-style caps for complete sentences;
  title-style caps for fragments.
- **Body** (optional): 1–2 sentences of additional context. Only include if it adds
  information the title doesn't cover. Don't use the body to explain what the buttons do —
  if the title and buttons are clear, the body isn't needed.
- **Actions**: Specific verb labels (see [Buttons and actions](#buttons-and-actions)).

### Tone guidance

Alerts are interruptions in moments that range from routine to critical. Dial up clarity
and directness. Dial back personality — this isn't the place for the voice to shine, it's
the place for the voice to stay calm and get out of the way.

### Checklist

- Could this be communicated without an interruption?
- Can someone understand it from title and buttons alone?
- Are button labels specific actions, not generic confirmations?
- Is the body actually adding information?

**Before:**

> Title: "App cannot open this file"
> Body: "You may need to download the latest update."
> Buttons: Yes / No

**After:**

> Title: "Can't Open 'Report.pdf'"
> Body: "Update the app to open this file format."
> Buttons: Update / Cancel

---

## Error messages

Errors are moments of friction. Your job is to get the person unstuck as fast as possible.

### Principles

1. **Say what happened** in plain language. Name the specific thing: "Can't connect to
   Wi-Fi" not "Network error."
2. **Explain why** if it helps — skip if the cause is obvious or irrelevant.
3. **Tell them what to do next.** Every error should have a clear path forward. Display
   errors close to the problem.

### What to avoid

- Technical jargon and error codes the person can't act on.
- Blaming the person ("invalid input"). Instruct instead: "Use only letters for your name."
- Interjections ("Oops!", "Uh oh!") — they trivialise the problem.
- Vague non-information: "Something went wrong. Please try again."
- "Please" and "sorry" as reflexive padding.
- Robotic messages with no helpful information, like "Invalid name."

### Tone guidance

Errors can be frustrating. Dial up clarity and helpfulness. Dial back friendliness — calm,
direct language respects the person's situation more than forced warmth. If language alone
can't address an error that's likely to affect many people, use that as a signal to rethink
the interaction.

**Before:**

> "Oops! You can't do that. Error code 1234567. Please try again."
> Buttons: Okay / Cancel

**After:**

> Title: "Billing Problem"
> Body: "To continue your subscription, add a new payment method."
> Buttons: Add Payment Method / Not Now

---

## Destructive actions

When an action can't be undone, the writing must be proportionally careful.

### Principles

- **Name the specific thing being destroyed**: "Delete 'Vacation Photos' album?" not
  "Delete this item?"
- **Make consequences explicit**: "You'll lose all 847 photos in this album."
- **Label buttons with the actual action**: "Delete Album" / "Keep Album" — not "Confirm"
  / "Cancel." (See [Buttons and actions](#buttons-and-actions).)
- **Avoid double-negative confusion.** "Cancel Cancellation" is a dark pattern. Write:
  "Cancel Platinum Subscription?" with buttons "Cancel Subscription" / "Keep Subscription."
- **Use the destructive style** (e.g. red button) for actions the person didn't deliberately
  initiate. When they chose the action (like Empty Trash), the confirmation doesn't need it.
- **Always include a Cancel button** as a clear, safe way out.

### Tone guidance

Dial up directness and specificity. Keep the voice calm and neutral. This is not a moment
for personality — it's a moment for clarity.

---

## Empty states

An empty state is a screen with no content yet — an opportunity to teach, guide, or
occasionally delight, but always with purpose.

### Principles

- **Tell the person what will appear here and how to make it happen**: "No Saved Episodes.
  Save episodes you want to listen to later, and they'll show up here."
- **Match tone to context.** Completed to-do list: celebratory. Empty search result:
  helpful, not whimsical.
- **Avoid idioms or humour that might not translate.**
- **Include a clear action** if possible: a button to create, add, or search.
- **Empty states are temporary** — don't put crucial information here.

### Tone guidance

Empty states are one of the best places for personality to shine through — especially
welcome screens and completed states. But make sure the content is useful and fits the
context. Education first, delight second.

---

## Onboarding and setup flows

Onboarding is your chance to welcome someone, explain the product's value, and help them get
started without wasting their time.

### Principles

- **Define the purpose of the whole flow and each screen.**
- **Lead with the why.** Tell people why you need what you're asking for.
- **Be honest about data and permissions**: explain how data will be used.
- **Welcome with warmth, but don't waste time.** One sentence capturing the product's value
  beats three paragraphs.
- **Use consistent button labels.** "Next" on every screen, "Get Started" at the beginning,
  "Done" at the end.
- **Each screen should say one thing.** Multiple ideas → multiple screens.

### Tone guidance

Onboarding is a warm moment. Dial up friendliness and helpfulness — the voice can shine here
more than almost anywhere else. But never sacrifice clarity for personality — people need to
understand what they're setting up.

---

## Notifications

Notifications reach people when they're doing something else.

### Principles

- **Lead with the key information**, not the instruction. "Your package arrives in 10
  minutes" beats "Open the app to check delivery status."
- **Be specific**: "8 minutes to Home — take Audubon Ave, traffic is light" gives real
  value. "Check your commute!" does not.
- **Respect attention.** If it's not time-sensitive or actionable, it probably shouldn't be
  a notification.
- **One idea per notification.** Link to a screen for more detail.
- **Choose the right delivery method.** Alert for critical interruptions, banner for
  informational, inline for contextual.

### Tone guidance

Notifications should feel like a helpful tap on the shoulder, not a demand for attention.
Keep the voice present but restrained. Match tone to urgency: a delayed delivery is
matter-of-fact; a milestone can be warmer.

---

## Accessibility labels

For screen reader users, accessibility labels _are_ the interface. Every interactive element
and every meaningful visual needs a thoughtful text label.

### Principles

- **Always add labels.** An unlabeled button reads as "button" — unusable. A person gives
  an app about 30 seconds; if they can't access the functionality, they delete it.
- **Be succinct, but disambiguate when needed.** "Add" is usually enough; use "Add to cart"
  when there are multiple "Add" buttons. Skip redundant context — in a music player, "Play"
  is sufficient.
- **Don't include the element type.** Screen readers announce "button," "link," etc.
  "Add button" produces "Add button, button."
- **Describe intent, not appearance.** An image label should convey meaning: "Person
  meditating with relaxed arms and forefingers touching" — not "circular image, blue
  background."
- **Update labels when state changes.** Play → Pause, etc.
- **Label loading states.** A spinner should announce "Loading."
- **Match richness to content.** Most labels should be succinct. But when the content
  itself is expressive — stickers, emoji, illustrations — a richer description serves the
  person better. A sticker of Cookie Monster might be labelled "Me happy face eat small
  cookie, om nom nom" because that captures the spirit of what a sighted person sees. The
  goal is an equivalent experience, not just a minimal one.
- **Use inclusive language.** "Person" rather than assumed gender.
- **Web:** Applies to `aria-label`, `aria-describedby`, and `alt` attributes.

---

## Buttons and actions

Buttons are the most-read text in any interface. People scan headers and buttons to
understand a screen — they may never read the body.

### Principles

- **Use specific verbs**: "Save Changes," "Send Message," "Download Report" — not "OK,"
  "Submit," or generic "Done."
- **Match the label to surrounding text.** If the body says "pair your device," the button
  should say "Start Pairing."
- **Paired choices must be clear independently**: "Keep Subscription" / "Cancel
  Subscription" — not "Confirm" / "Cancel."
- **Destructive actions**: visually distinct (e.g. red), labelled with what they destroy.
- **Avoid "OK"** unless purely informational. "OK" is ambiguous — does it mean "do it" or
  "I understand"?
- **Prefer verbs over "Yes" / "No."** The button labels alone should convey the choice.
- **Be consistent.** Add button labels to your word list.

---

## Instructional and inline copy

Field hints, tooltips, inline guidance, step descriptions, settings labels.

### Principles

- **Lead with the benefit**: "To keep your streak, solve today's crossword."
- **Be direct.** No "simply," no "quickly."
- **Place instructions where the person is looking.**
- **One instruction at a time.**
- **For text fields**: label clearly, use hint text for format examples
  ("name@example.com"). Show errors next to the field.

---

## Settings and preferences

Settings are utilitarian — people visit to find something specific and get out.

### Principles

- **Name settings plainly.**
- **Add a short description if the label isn't enough.** Describe what the setting does when
  on — people infer the opposite.
- **Provide direct links** to navigate to a setting rather than describing its location.
