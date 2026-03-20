$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$imagesRoot = Join-Path $repoRoot "Immagini"
$outputPath = Join-Path $repoRoot "gallery.json"
$outputScriptPath = Join-Path $repoRoot "gallery-data.js"
$allowedExtensions = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".avif")

function Convert-CategoryName {
  param([string]$FolderName)

  $normalized = $FolderName -replace "_", " "
  $parts = $normalized -split "\s+"

  return ($parts | Where-Object { $_ } | ForEach-Object {
    if ($_.Length -gt 1) {
      $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
    } else {
      $_.ToUpper()
    }
  }) -join " "
}

if (-not (Test-Path $imagesRoot)) {
  throw "Cartella immagini non trovata: $imagesRoot"
}

$items = Get-ChildItem -Path $imagesRoot -Directory |
  Sort-Object Name |
  ForEach-Object {
    $folder = $_
    $category = Convert-CategoryName $folder.Name

    Get-ChildItem -Path $folder.FullName -File |
      Where-Object { $allowedExtensions -contains $_.Extension.ToLower() } |
      Sort-Object Name |
      ForEach-Object {
        [PSCustomObject]@{
          category = $category
          image = ("Immagini/{0}/{1}" -f $folder.Name, $_.Name).Replace("\", "/")
        }
      }
  }

$payload = [PSCustomObject]@{
  generatedAt = (Get-Date).ToString("s")
  items = @($items)
}

$json = $payload | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText($outputPath, $json, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($outputScriptPath, "window.__galleryData = $json;", [System.Text.UTF8Encoding]::new($false))
