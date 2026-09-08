# Security policy

## Reporting a vulnerability

Open a [GitHub security advisory](https://github.com/phamquyetthang/declutter/security/advisories/new),
or an issue if the problem is not sensitive. Please include your OS, `bash
--version`, and the smallest reproduction you can manage.

## What counts as a security issue here

`declutter` deletes files. The severe failure modes are about deleting the wrong
thing, or being made to:

- **Deleting outside the declared scope** — anything the README lists under "What
  it never touches", or any path outside `$HOME` and the documented system
  locations.
- **Path handling** — a directory name containing spaces, newlines, quotes or
  shell metacharacters that causes the wrong path to be removed, or that escapes
  a quoted expansion.
- **`cmd` item injection** — a value interpolated into a `cmd` action (a `brew
  --cache` or `go env GOCACHE` result, for instance) that could execute something
  unintended.
- **`sudo` escalation** — any way the tool uses `sudo` beyond the specific Ubuntu
  system items, or uses it when the user passed `--sudo no`.
- **`--dry-run` deleting anything at all.** That is the promise the whole tool
  rests on.

Reports of the shape "this tool can delete files" are not vulnerabilities — that
is what it does, with confirmation, in the tiers documented in the README.

## Design guarantees

- No network calls anywhere in the tool. `install.sh` is the only thing that
  downloads, and only from GitHub.
- No telemetry, no analytics, no data leaves the machine.
- Nothing is deleted without confirmation: the user presses Enter, or passes
  `--yes`.
- Red-tier items are never deleted by the tool, and no flag changes that.
- Every action is appended to `~/.declutter.log`, so what happened is auditable
  after the fact.

## Supported versions

The latest release on `main` is the supported one. Fixes land there.
