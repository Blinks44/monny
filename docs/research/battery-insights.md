# Battery insight sources — 2026-11-09

[DES-007](../tasks/DES-007-recovery-charging-sleep.md) reuses the existing shared battery reader, native charge-limit state and gauge power freshness; no dependency or additional privileged/system command is needed.

Charging guidance is observational. Apple documents that a connected adapter can power the Mac without charging its battery and may be insufficient under load: [Not Charging](https://support.apple.com/guide/mac-help/if-your-battery-status-is-not-charging-mh20876/mac). A rating alone does not identify the cause. Unknown system policies remain unknown.

Sleep intervals use [NSWorkspace.willSleepNotification](https://developer.apple.com/documentation/appkit/nsworkspace/willsleepnotification) and [didWakeNotification](https://developer.apple.com/documentation/appkit/nsworkspace/didwakenotification), registered on the workspace notification center. No sleep prevention assertion, wake request, log scraping or polling during sleep. The sleep handler captures the existing recent shared reading and returns immediately; after wake the shared sampler waits for the gauge UpdateTime to advance. If no fresh endpoint arrives within two minutes, report unavailable. Pending intervals are memory-only; only bounded completed reports persist locally.

Endpoint changes measure net charge change across an interval, including unobserved activity. Identical on-battery endpoints cannot rule out intermediate charging or wake activity. Do not attribute loss to a process or declare continuous sleep. Initial runtime checks on real battery hardware remain open.
