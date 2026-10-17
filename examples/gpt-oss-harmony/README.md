# GPT-OSS Harmony protocol and template support

This directory contains the external template and contracts for the opt-in GPT-OSS Harmony profile on llama.cpp v0.6.0. It replaces the older fork-review bundle in brutuscat/llama.cpp#2.

The server parses native recipient names, but does not execute browser, Python, shell or file operations. The caller must provide the declared capabilities and execute the returned tool calls. This is a private-fork integration, not an upstream submission.

## Contents

- `gpt-oss-native-tools.jinja` is an external overlay derived from the GPT-OSS template identified by SHA-256 `b2215de6da8ba369957eece8c5aa18f4af94f6c4d311d85e691373a421d80e89`.
- `native-recipient-contract.json` records dotted native and ordinary function recipients that must round-trip.
- `harmony-native-template.json` is a rendering fixture for browser, container, repo-browser, Python, top-level patch, and ordinary function calls.
- `run-template-contract.ps1` checks the rendered template with a caller-supplied `test-chat-template` binary.

## Opt-in use

Supply the overlay to a compatible Harmony `llama-server` instance:

```powershell
llama-server --jinja --chat-template-file .\examples\gpt-oss-harmony\gpt-oss-native-tools.jinja <other-isolated-options>
```

Native browser, `container.exec`, `repo_browser.*`, bare `python`, and top-level `apply_patch` are declared only when the caller supplies the corresponding `builtin_tools` template argument. Loading this template does not enable an executor. Keep production files and service settings unchanged until a separately approved cutover.

Tool descriptions and schemas come from the caller's API `tools` payload. The template does not choose a citation format, browser provider, call budget, filesystem root or Python runtime. Each adapter must supply those policies in its tool descriptions. Open WebUI supplies its browser citation policy through `browser.search` and retains its line-citation reminders in browser results. Other callers can supply their own citation convention without changing this template.

## Protocol contract

- Calls are sequential: one tool call per assistant message.
- Dotted recipients accept both their native name and the legacy `functions.` prefix.
- With `python` in `builtin_tools`, bare `python` carries raw code and becomes a JSON `code` field at the API boundary. `functions.python` keeps its declared JSON schema. Other models and ordinary functions named `python` are unaffected.
- With `apply_patch` in `builtin_tools`, bare `apply_patch` and `functions.apply_patch` accept either a JSON argument object or raw text starting with `*** Begin Patch`; raw text becomes a JSON `patch` field. Without that capability, only the ordinary `functions.apply_patch` JSON route is available.
- System/developer instructions and tool results remain in history order. Python retains newlines, Unicode and trailing whitespace.
- Raw argument streaming emits JSON string prefixes; concatenated deltas must equal the final non-streaming arguments.

## Template contract

Build or locate llama.cpp's `test-chat-template` binary, then run:

```powershell
.\examples\gpt-oss-harmony\run-template-contract.ps1 -TestBinary C:\path\to\test-chat-template.exe
```

The parser implementation itself and its unit fixture remain in the native `common/` and `tests/` locations of this branch.

## Provenance

The original support bundle was reviewed at `5ac492bf`. This version ports its behavior to `d81235049384534c167caea52b85a694f6103d14`, with the successful-SSE-completion fix retained in the base branch. Raw argument conversion is selected by an explicit parser tag, rather than by a tool name in the shared mapper.
