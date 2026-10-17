# SwiftUI Accessibility Checklist

This checklist is derived from Apple's official accessibility guidance and is intended for **manual verification** after applying changes suggested by the SwiftUI Accessibility Auditor.

Use VoiceOver, Dynamic Type, and keyboard navigation where applicable.

---

## VoiceOver & Semantics
- [ ] All icon-only buttons have a clear, meaningful label
- [ ] Labels match visible text where possible for predictable Voice Control commands
- [ ] No duplicated announcements (parent + child announcing same text)
- [ ] Headers are correctly exposed as headers
- [ ] Grouping preserves essential child text, state, and independently actionable controls
- [ ] Reading order matches the visual and logical layout
- [ ] Custom tappable views expose both button semantics and an activation action

## Custom Controls & Gesture Input
- [ ] Custom controls expose purpose, current value/state, available actions, and interaction feedback
- [ ] Single-axis adjustable controls support increment/decrement and announce the updated value
- [ ] Multidimensional or discrete gestures have clearly named custom-action alternatives
- [ ] Passthrough interaction starts at a useful activation point and does not flood VoiceOver with announcements
- [ ] Direct Touch is limited to raw-gesture surfaces, requires activation when appropriate, and has non-gesture alternatives
- [ ] Silent Direct Touch is used only when the control provides equivalent audio feedback

## Reading & Text Experiences
- [ ] Long-form text supports granular navigation, continuous reading, and text selection where relevant
- [ ] Standard accessible text views are preferred over custom-rendered text when possible
- [ ] Separate text regions preserve read-all flow across pages or sections
- [ ] Custom-rendered text exposes enough structure for VoiceOver, Speak Screen, and Accessibility Reader
- [ ] The VoiceOver Lines rotor moves across linked text elements without dead ends
- [ ] Text selection works by line, word, and character where the reading experience requires it
- [ ] A VoiceOver read-all gesture turns pages and continues at the correct text element
- [ ] Text-selection custom actions appear in the Edit rotor where supported

## Dynamic Type
- [ ] Text scales correctly up to the largest accessibility sizes
- [ ] Important information is not lost due to truncation
- [ ] Layout adapts naturally without relying on minimumScaleFactor
- [ ] No fixed font sizes block text scaling

## Focus & Keyboard Navigation (macOS / iPad)
- [ ] Screen is fully usable with keyboard only
- [ ] Focus order is predictable and logical
- [ ] Custom components can receive focus when needed
- [ ] Focus is not trapped or lost after interactions
- [ ] Custom actions are reachable without touch-only gestures
- [ ] Keyboard focus and accessibility focus are verified independently
- [ ] Initial focus and focus restoration do not interrupt the current task

## Color & Contrast
- [ ] Information is not conveyed by color alone
- [ ] States (error, selected, disabled) are understandable without color
- [ ] System or semantic colors are preferred where possible

## Touch Targets (iOS)
- [ ] Tappable elements are at least ~44x44 pt
- [ ] Hit areas are expanded without changing visual layout when needed
- [ ] Custom tappable containers remain activatable with VoiceOver

## Voice Control & Switch Control (iOS / iPadOS)
- [ ] Voice Control "Show names" exposes clear, non-duplicated labels
- [ ] Switch Control can reach all interactive elements in a logical scan order
- [ ] Grouping reduces unnecessary scan stops without hiding actions

## Motion
- [ ] Animations are subtle and do not block interaction
- [ ] Reduce Motion preferences are respected where applicable

## WWDC26 / OS 27 Readiness
- [ ] Resizing, iPhone Mirroring, iPad windowing, and toolbar overflow keep text readable and focus order stable
- [ ] Liquid Glass, translucent materials, and scroll edge effects remain legible with Reduce Transparency and Increase Contrast
- [ ] Reorder, drag/drop, swipe actions, and gesture-first flows expose purpose, value, actions, and feedback
- [ ] New accessibility APIs are gated by documented OS/platform availability with accessible fallbacks
- [ ] Media screens expose authored and supported generated subtitles and respect system subtitle styles
- [ ] Subtitle styles can be previewed during playback without obscuring controls or active captions
- [ ] Feature, tab, menu, and action names are clear, localizable, and usable with Voice Control

---

## Instrumented Verification and Scope
- [ ] Accessibility Inspector checks the affected screens when a runnable app is available
- [ ] Compatible existing UI tests audit representative screen states where useful; false positives are investigated before filtering
- [ ] Automated results are supplemented with manual assistive-technology checks
- [ ] Results identify the OS/device, checks performed, and checks still pending
- [ ] App Store support declarations, when in scope, are backed by tested core tasks rather than one passing screen

## Assistive Access (when supported or requested)
- [ ] Essential tasks remain available in the tailored iOS/iPadOS experience
- [ ] Assistive Access scene/environment APIs are gated by their documented availability

## Final validation
- [ ] Screen is usable with VoiceOver enabled
- [ ] Screen remains usable at extreme text sizes
- [ ] No new accessibility regressions introduced
