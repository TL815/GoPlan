# Encoding Guard

## 2026-07-07 Chinese mojibake incident

`lib/main.dart` was accidentally rewritten through a PowerShell path that did not preserve UTF-8 Chinese text. Visible Chinese copy became mojibake. The known bad character patterns are maintained in `tool/check_encoding.ps1`.

Rules from now on:

- Do not write Chinese source text through ad hoc PowerShell heredocs or shell redirection.
- Use `apply_patch` for manual edits, or write escaped Unicode from a UTF-8-safe script only when bulk repair is unavoidable.
- After touching Chinese copy or asset names, run:

```powershell
.\tool\check_encoding.ps1
```

- Also run `dart format` and `git diff --check` before handing the project back.
