param(
  [string]$RepoPath = "D:\Games\PrismLauncher\instances\1.21.1",
  [string]$Remote = "https://github.com/fractaal/councilcraft-mods-repo"
)

function Test-Command($Name) { $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

if (-not (Test-Command git)) {
  Write-Error "git is not installed or not on PATH."; exit 1
}

# Avoid safe.directory errors on some setups
try { git config --global --add safe.directory "$RepoPath" *> $null } catch { }

$gitDir = Join-Path $RepoPath ".git"
$needsAdoption = $false

# Check if .git exists
if (-not (Test-Path $gitDir)) {
  $needsAdoption = $true
  Write-Host "[ADOPT] Not a Git repo yet. Initializing..."
} else {
  # .git exists, but check if remote 'origin' is properly configured
  $currentRemote = git -C $RepoPath remote get-url origin 2>$null
  if ([string]::IsNullOrWhiteSpace($currentRemote) -or $currentRemote -ne $Remote) {
    Write-Host "[ADOPT] Git repo exists but remote is not configured correctly."
    Write-Host "[ADOPT] Current remote: $currentRemote"
    Write-Host "[ADOPT] Expected remote: $Remote"
    $needsAdoption = $true
  }
}

# ADOPT STEP: Initialize or fix remote configuration
if ($needsAdoption) {
  Write-Host "[ADOPT] Configuring repo to connect to $Remote ..."
  
  # Backup current mods/ if it exists
  $modsPath = Join-Path $RepoPath "minecraft\mods"
  if (Test-Path $modsPath) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $RepoPath ("backup-pre-git-" + $stamp)
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item $modsPath -Destination $backupDir -Recurse -Force
    Write-Host "[ADOPT] Backed up minecraft/mods/ to $backupDir"
  }
  
  # Initialize Git if needed
  if (-not (Test-Path $gitDir)) {
    git -C $RepoPath init | Out-Null
  }
  
  # Set or update remote
  try { git -C $RepoPath remote remove origin 2>$null } catch { }
  git -C $RepoPath remote add origin $Remote
  
  # Fetch and detect default branch
  Write-Host "[ADOPT] Fetching from remote..."
  git -C $RepoPath fetch origin --prune
  $defaultBranch = (git -C $RepoPath remote show origin | Select-String "HEAD branch: " | ForEach-Object { $_.Line.Split(":")[1].Trim() })
  if ([string]::IsNullOrWhiteSpace($defaultBranch)) { $defaultBranch = "main" }
  
  # Checkout tracking branch
  git -C $RepoPath checkout -B $defaultBranch --track "origin/$defaultBranch"
  Write-Host "[ADOPT] Adoption complete. Now tracking origin/$defaultBranch."
} else {
  Write-Host "[INIT] Git repo already configured correctly."
}

# PULL STEP: Always pull latest changes
Write-Host "[PULL] Pulling updates in $RepoPath ..."
git -C $RepoPath pull --rebase --autostash

# Brief status after pull
Write-Host "[PULL] Post-pull status (tracked files):"
git -C $RepoPath status -s --untracked-files=no

Write-Host "Ready to launch!"
