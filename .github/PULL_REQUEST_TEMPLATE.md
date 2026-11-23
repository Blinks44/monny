## Summary

<!-- Describe what this PR changes and why. Link related issues if any (e.g. Fixes #123). -->

## Verification

- [ ] `apps/monny/scripts/dev.sh build`, `test`, and `lint` pass (for app changes)
- [ ] New or updated tests cover the changed behavior
- [ ] UI changes checked in light & dark mode and across localizations
- [ ] Charging logic preserves fail-safe rules in `docs/ENGINEERING.md` (if touched)
- [ ] If `apps/website/` changed: `pnpm --dir apps/website check` and `pnpm --dir apps/website build` pass
