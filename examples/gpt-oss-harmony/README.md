# GPT-OSS Harmony protocol and template support

This directory is a fork-review support bundle for the isolated GPT-OSS Harmony profile. It makes the complete L1/L2/L3 protocol work visible beside the llama.cpp implementation in this Draft PR.

It is not an upstream-ready llama.cpp product integration. A later upstream proposal would split the small generic recipient-parser fix from this model/profile-specific template and its private-profile fixtures.

## Contents

- `gpt-oss-native-tools.jinja` is an external overlay derived from the GPT-OSS template identified by SHA-256 `b2215de6da8ba369957eece8c5aa18f4af94f6c4d311d85e691373a421d80e89`.
- `native-recipient-contract.json` records dotted native and ordinary function recipients that must round-trip.
- `harmony-native-template.json` is a rendering fixture for browser, container, repo-browser, and ordinary function calls.
- `run-template-contract.ps1` checks the rendered template with a caller-supplied `test-chat-template` binary.

## Isolated use only

Supply the overlay only to the isolated Harmony `llama-server` instance:

```powershell
llama-server --jinja --chat-template-file .\examples\gpt-oss-harmony\gpt-oss-native-tools.jinja <other-isolated-options>
```

Do not replace the template, binary, service configuration, port, or API key of the Guardian deployment. Native browser, `container.exec`, and `repo_browser.*` are declared only when the isolated profile explicitly supplies their capability.

## Template contract

Build or locate llama.cpp's `test-chat-template` binary, then run:

```powershell
.\examples\gpt-oss-harmony\run-template-contract.ps1 -TestBinary C:\path\to\test-chat-template.exe
```

The parser implementation itself and its unit fixture remain in the native `common/` and `tests/` locations of this branch.

## Provenance

L1 is the net diff from `aa7a8e0d774a1acb5ca3891220985c54c976dc81` to `251ed9309633a181d1dca5b2b1b82a857959dcd2`. Do not replay the abandoned intermediate commits `fef317d6` or `472831f3`.
