# NVMe SMART SSD health: check

- Date: 2026-10-19; historical revision after `1962fb7`, uncommitted at observation.
- Context: MacBook Pro M1 Max, internal NVMe SSD, macOS 27.0.1; agent-observed, ordinary user.
- Method: standalone probe and app use the same NVMe SMART user client; no independent `smartctl` comparison. Personal wear and lifetime-write values omitted.

Probe and Disk page agreed on percentage used/derived health, critical warning, available spare and rounded data-written units. NVMe-log temperature and SMC SSD temperature differed by 1 °C. This proves access and consistent decoding/display, not vendor accuracy.

Open: compare with `smartctl -a disk0` or another independent tool; check controller selection with an external NVMe attached. Owned by [CORE-003](../tasks/CORE-003-history.md).
