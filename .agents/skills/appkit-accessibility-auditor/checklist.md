# AppKit Accessibility Checklist

This checklist is derived from Apple's official accessibility guidance and is intended for **manual verification** after applying changes suggested by the AppKit Accessibility Auditor.

Use VoiceOver and keyboard navigation as primary validation tools.

---

## VoiceOver Roles & Labels
- [ ] All actionable elements expose clear labels
- [ ] Labels match visible text where possible for predictable Voice Control commands
- [ ] Custom views expose appropriate accessibility roles
- [ ] Help text clarifies behavior where necessary
- [ ] No duplicated or confusing announcements

## Keyboard Navigation & Focus
- [ ] App is fully usable without a mouse
- [ ] Tab / Shift-Tab navigation reaches all interactive elements
- [ ] Focus order is predictable and logical
- [ ] No focus traps or dead ends
- [ ] Custom actions are reachable without pointer-only gestures

## Grouping & Reading Order
- [ ] Related content is grouped appropriately
- [ ] VoiceOver reading order matches the visual structure
- [ ] Dense layouts avoid excessive VoiceOver stops

## Tables & Outline Views
- [ ] Rows are understandable when read by VoiceOver
- [ ] Selection state is discoverable
- [ ] Column headers are accessible when present
- [ ] Custom cell views expose meaningful labels and values

## Custom Controls
- [ ] Custom controls behave like their native counterparts
- [ ] Controls are operable via keyboard (Space / Enter)
- [ ] Controls expose an accessibility press/action path where applicable
- [ ] State changes provide clear feedback
- [ ] Complex custom controls expose purpose, value/state, available actions, and interaction feedback
- [ ] Gesture recognizers, context menus, selection, and drag/drop preserve keyboard and accessibility action paths
- [ ] Adjustable controls expose value changes, keyboard increment/decrement, and meaningful feedback
- [ ] Multidimensional or gesture-driven controls expose named accessibility actions and keyboard equivalents

## Voice Control & Switch Control
- [ ] Voice Control can identify controls by clear, non-duplicated names
- [ ] Switch Control can reach interactive elements in a logical scan order
- [ ] Grouping reduces unnecessary scan stops without hiding actions

## Reading & Text Experiences
- [ ] Long-form text supports granular navigation, continuous reading, and text selection where relevant
- [ ] `NSTextView` or standard text views are preferred over custom-rendered text when possible
- [ ] Custom-rendered text or scanned pages expose text structure instead of a single image/group
- [ ] Page turns and separate text regions preserve read-all flow for VoiceOver, Speak Screen, and Accessibility Reader where available
- [ ] Shared text UI elements preserve continuous VoiceOver navigation across regions
- [ ] Paginated reading resumes at the next text element after a page turn

## Text & Scaling
- [ ] Text is readable at larger display or font scales
- [ ] Layout does not clip important content
- [ ] System fonts are preferred where possible

## Announcements & Updates
- [ ] Dynamic content updates are announced appropriately
- [ ] Announcements use the appropriate AppKit notification and localized payload
- [ ] Updates preserve current focus unless a meaningful transition requires a change
- [ ] Announcements are meaningful and not excessive

## Color & Contrast
- [ ] States are not conveyed by color alone
- [ ] Icons, text, or VoiceOver cues reinforce state

## WWDC26 / OS 27 Readiness
- [ ] Resizable windows, sidebars, toolbars, and changing content areas preserve keyboard and VoiceOver order
- [ ] Liquid Glass, updated window chrome, and translucent materials remain legible with Reduce Transparency and Increase Contrast
- [ ] Menu items remain understandable if images are hidden in menu bar contexts
- [ ] Media screens expose subtitle selection and respect system subtitle styles
- [ ] Supported generated/translated subtitle tracks are clearly identified and selectable
- [ ] Subtitle style preview is available during playback and remains accessible with VoiceOver and keyboard input
- [ ] New APIs are gated by documented OS/platform availability with authored-subtitle fallbacks
- [ ] Drag/drop, context menus, Siri/App Intents entry points, and generated actions expose purpose, value, actions, and feedback without pointer-only interaction
- [ ] Feature, toolbar, menu, and action names are clear, localizable, and usable with Voice Control

---

## Instrumented Verification and Scope
- [ ] Accessibility Inspector checks the affected screens when a runnable app is available
- [ ] Compatible existing UI tests audit representative screen states where useful; false positives are investigated before filtering
- [ ] Automated results are supplemented with manual assistive-technology checks
- [ ] Results identify the OS/device, checks performed, and checks still pending
- [ ] App Store support declarations, when in scope, are backed by tested core tasks rather than one passing screen

## Final validation
- [ ] Screen is usable with VoiceOver enabled
- [ ] App is fully operable using keyboard only
- [ ] Non-pointer input remains usable where relevant
- [ ] No accessibility regressions introduced
