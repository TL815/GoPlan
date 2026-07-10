param(
  [string[]]$Paths = @("lib", "documentation", "README.md")
)

$ErrorActionPreference = "Stop"

$badCodePoints = @(
  0x95BA,
  0x5A11,
  0x59A4,
  0x9227,
  0x9357,
  0x9354,
  0x93C8,
  0x93BC,
  0x699B,
  0x7F02,
  0x951B,
  0x7AD4,
  0x71BC,
  0x621E,
  0xE17B,
  0xE1AE,
  0xFFFD
)
$badChars = $badCodePoints | ForEach-Object { [char]$_ }
$hits = @()

foreach ($path in $Paths) {
  if (-not (Test-Path -LiteralPath $path)) {
    continue
  }

  $items = if (Test-Path -LiteralPath $path -PathType Container) {
    Get-ChildItem -LiteralPath $path -Recurse -File -Include *.dart,*.md,*.yaml,*.yml
  } else {
    Get-Item -LiteralPath $path
  }

  foreach ($item in $items) {
    if ($item.FullName -match "\\.codex-runtime\\" -or $item.Name -like "*.bak") {
      continue
    }

    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $item.FullName -Encoding UTF8) {
      $lineNumber++
      foreach ($badChar in $badChars) {
        if (-not $line.Contains($badChar)) {
          continue
        }
        $relative = Resolve-Path -LiteralPath $item.FullName -Relative
        $hits += "${relative}:${lineNumber}: ${line}"
        break
      }
    }
  }
}

if ($hits.Count -gt 0) {
  Write-Error ("Potential mojibake found:`n" + ($hits -join "`n"))
  exit 1
}

Write-Host "Encoding check passed."
