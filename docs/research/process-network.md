# Process network rates

Decision: 2026-11-04, [APP-017](../tasks/APP-017-process-network.md).

Use the installed Apple `/usr/bin/nettop`, not a custom binding to private NetworkStatistics. The documented command is `nettop -n -P -L 2 -s 1 -d -x -J bytes_in,bytes_out -t external`: TCP/UDP process summaries, numeric bytes, no hostname resolution, external interfaces, first baseline discarded and second one-second delta used as bytes/second. Read the installed `man nettop` for option semantics. A fixed executable and arguments run directly, without a shell, root, helper, packet capture, Location permission or network request.

The shared sampler requests these bounded reads only for the popover's Network sort or the dashboard Network page. It subtracts sample duration from the configured refresh delay. LocalCommand reuses the existing AI command execution's cancellation, 3-second network timeout, child cleanup and 256 KiB combined output bound; AI commands retain their original environment and limits. No process names, PIDs, connections or destinations are persisted.

Parse named CSV columns, require the second sample and nonnegative numeric counters, reject duplicates/malformed output. Join only processes whose kernel start identity matches across the interval; a new/recycled process starts unavailable. A readable stable process absent from a successful socket summary has no reported traffic (zero); command/format failure leaves every rate unavailable. Group helpers using the existing app owner and sum both directions; sort by their combined rate with PID ties. A grouped value with an unavailable member stays unavailable.

Scope: socket accounting differs from physical interface bytes (protocol overhead, VPN attribution, system daemons and unreadable processes). Do not promise exact agreement with the interface total or ISP billing. The one-second observation is a recent rate, not a cumulative per-process total, and short-lived processes may disappear between reads. Daily totals remain explicitly labelled estimates from recorded history buckets; days with no readings show a dash. No process history is introduced.

## Alternatives and provenance

- Apple public interface counters remain the whole-Mac source. `proc_pid_rusage` supplies CPU/memory/energy/disk, not network bytes.
- Direct NetworkStatistics is private and would require an adapter and ABI/lifecycle maintenance. It is unnecessary while the system utility meets the bounded use case.
- [Stats](https://github.com/exelban/stats) also uses nettop. Its [reported unbounded-reader hang](https://github.com/exelban/stats/issues/3499) supports requiring timeout/cancellation. The project is maintained under the [MIT license](https://github.com/exelban/stats/blob/master/LICENSE); its implementation code was not copied.
- [bandwidther](https://github.com/simonw/bandwidther) illustrates the system-command approach; no code/dependency was imported. No suitable public system counter or needed maintained Swift Package Index dependency was identified; a small parser over the installed utility adds no third-party licensing/runtime dependency.

## Evidence and remaining checks

On M1 Max/macOS 27.2, ordinary-user CSV probes succeed; the agent sandbox denies NStatManagerCreate, so probes/builds use normal user execution. A wait4 measurement of one two-sample invocation recorded 0.0123 CPU seconds and about one second elapsed. A separate live nettop process showed 0.02 accumulated CPU seconds after three seconds. These are source probes, not a full app energy profile or other-model guarantee. Raw CSV and samples stay in temporary local storage.

Compare the installed signed build during sustained download/upload and app grouping, including VPN/browser attribution. Verify macOS 15/26 and lifecycle transitions when hardware is available. Existing network/sampling baseline acceptance does not accept this addition.
