# Security Policy

## Scope

A collection of macOS AppleScript Quick Actions that shell out to local tools (FFmpeg,
ExifTool, sips, Pixelmator Pro) and operate on user-selected files in Finder. The scripts
make no network requests, read no credentials, and do not escalate privileges.

## Supported versions

Only the current `main` branch is supported. There are no tagged releases. If you have
pasted a script into an Automator Quick Action, re-paste from `main` to pick up fixes —
`~/Library/Services/*.workflow` bundles inline the source at copy-paste time and do not
auto-update.

## Reporting a vulnerability

If you have found a security issue — for example, command injection via a crafted filename,
path traversal in an output path, or an unsafe external-tool invocation — please report it
privately rather than opening a public issue. Use GitHub's **Report a vulnerability** button
under the repo's **Security** tab (private security advisory).

Include:

- A short description of the issue
- The script(s) affected
- A minimal reproduction (file selection + shell environment)

Expect an acknowledgement within a week. Confirmed issues are patched on `main`; the fix
commit will credit the reporter unless you ask otherwise.

## Out of scope

- Bugs in the external tools themselves (FFmpeg, ExifTool, sips, Pixelmator Pro) — report
  those upstream.
- Issues that require the attacker to already control the user's Finder selection or
  filesystem paths. These utilities are designed to be driven by the user's own selection.
- As stated in `README.md`: "Personal utility scripts. Use at your own risk."
