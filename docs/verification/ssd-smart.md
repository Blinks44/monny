# NVMe SMART SSD health: check

- Date: 2026-10-19
- Revision: `main` after 1962fb7 (uncommitted)
- Mac: MacBook Pro 14″ 2021 (MacBookPro18,2), Apple M1 Max, 1 TB internal SSD, macOS 27.0.1
- Method: agent-observed. A standalone probe and the app read the same NVMe SMART user client as an ordinary user; no reference tool (`smartctl`) is installed, so this proves the source works without privileges, not that the vendor values are right.

| Reading | Probe | App (Disk page, Russian UI) |
| --- | --- | --- |
| Percentage used (wear) | 1 % | 1 % (health 99 %) |
| Critical warning / available spare | 0 / 100 % (threshold above it) | "Verified" |
| Data written | 41.0 TB | 41 TB |
| Temperature (NVMe log 307 K vs SMC `TH0x`) | 34 °C | 35 °C (SMC) |

Open: compare with `smartctl -a disk0` or another tool; check which controller is read with an external NVMe drive attached.
