param(
  [string]$RepoPath = "D:\Games\PrismLauncher\instances\1.21.1",
  [string]$Remote = "https://github.com/fractaal/councilcraft-mods-repo"
)

function Test-Command($Name) { $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }

# Logo text (intentionally cringy 2010-style)
$script:LogoText = "xXxCouncilCraftxXx"

function Show-Notification {
  param(
    [string]$StatusMessage,
    [string]$StatusColor = "Green"  # Green, Red, Orange, Blue
  )
  
  # Escape the message for PowerShell
  $escapedMessage = $StatusMessage -replace "'", "''"
  $logoText = $script:LogoText
  
  # Create temp script file to avoid escaping hell
  $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
  
  $code = @"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

`$form = New-Object System.Windows.Forms.Form
`$form.Text = 'CouncilCraft Mods Sync'
`$form.Size = New-Object System.Drawing.Size(700,400)
`$form.StartPosition = 'CenterScreen'
`$form.FormBorderStyle = 'FixedDialog'
`$form.MaximizeBox = `$false
`$form.MinimizeBox = `$false
`$form.TopMost = `$true
`$form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)

# RGB Wave Logo - using RichTextBox for per-character coloring
`$logoBox = New-Object System.Windows.Forms.RichTextBox
`$logoBox.Location = New-Object System.Drawing.Point(40,30)
`$logoBox.Size = New-Object System.Drawing.Size(620,100)
`$logoBox.Text = '$logoText'
`$logoBox.Font = New-Object System.Drawing.Font('Segoe UI',44,[System.Drawing.FontStyle]::Bold)
`$logoBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
`$logoBox.BorderStyle = 'None'
`$logoBox.ReadOnly = `$true
`$logoBox.TabStop = `$false
`$logoBox.Cursor = [System.Windows.Forms.Cursors]::Arrow
`$logoBox.SelectionAlignment = 'Center'
`$form.Controls.Add(`$logoBox)

# Status Message
`$statusLabel = New-Object System.Windows.Forms.Label
`$statusLabel.Location = New-Object System.Drawing.Point(20,145)
`$statusLabel.Size = New-Object System.Drawing.Size(660,220)
`$statusLabel.Text = '$escapedMessage'
`$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI',12,[System.Drawing.FontStyle]::Bold)
`$statusLabel.TextAlign = 'TopCenter'

# Set color based on status
switch ('$StatusColor') {
  'Green'  { `$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 255, 100) }
  'Red'    { `$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 100, 100) }
  'Orange' { `$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 100) }
  'Blue'   { `$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255) }
  default  { `$statusLabel.ForeColor = [System.Drawing.Color]::White }
}
`$form.Controls.Add(`$statusLabel)

# RGB Wave Animation - each character gets offset color for wave effect
`$hueOffset = 0
`$rgbTimer = New-Object System.Windows.Forms.Timer
`$rgbTimer.Interval = 50
`$rgbTimer.Add_Tick({
  `$script:hueOffset = (`$script:hueOffset + 5) % 360
  `$text = `$logoBox.Text
  `$charSpacing = 360.0 / `$text.Length
  
  for (`$i = 0; `$i -lt `$text.Length; `$i++) {
    # Calculate hue for this character with wave offset
    `$charHue = (`$script:hueOffset + (`$i * `$charSpacing)) % 360
    `$h = `$charHue / 60.0
    `$x = (1 - [Math]::Abs((`$h % 2) - 1)) * 255
    
    if (`$h -lt 1) { `$r=255; `$g=[int]`$x; `$b=0 }
    elseif (`$h -lt 2) { `$r=[int]`$x; `$g=255; `$b=0 }
    elseif (`$h -lt 3) { `$r=0; `$g=255; `$b=[int]`$x }
    elseif (`$h -lt 4) { `$r=0; `$g=[int]`$x; `$b=255 }
    elseif (`$h -lt 5) { `$r=[int]`$x; `$g=0; `$b=255 }
    else { `$r=255; `$g=0; `$b=[int]`$x }
    
    # Apply color to this character
    `$logoBox.Select(`$i, 1)
    `$logoBox.SelectionColor = [System.Drawing.Color]::FromArgb(`$r, `$g, `$b)
  }
  `$logoBox.Select(0, 0)  # Deselect
})
`$rgbTimer.Start()

# Auto-close after 4 seconds
`$closeTimer = New-Object System.Windows.Forms.Timer
`$closeTimer.Interval = 4000
`$closeTimer.Add_Tick({ `$form.Close(); `$closeTimer.Stop(); `$rgbTimer.Stop() })
`$closeTimer.Start()

`$form.Add_Shown({`$form.Activate()})
[void]`$form.ShowDialog()
"@
  
  Set-Content -Path $tempScript -Value $code -Encoding UTF8
  
  # Start hidden process - no console flash
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "powershell.exe"
  $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tempScript`""
  $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
  $psi.CreateNoWindow = $true
  [System.Diagnostics.Process]::Start($psi) | Out-Null
  
  # Clean up temp file after a delay
  Start-Job -ScriptBlock { Start-Sleep -Seconds 10; Remove-Item $args[0] -ErrorAction SilentlyContinue } -ArgumentList $tempScript | Out-Null
}

if (-not (Test-Command git)) {
  Write-Host "[SETUP] Git not found. Attempting to install via winget..."
  
  if (Test-Command winget) {
    Write-Host "[SETUP] Installing Git..."
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    
    # Refresh PATH to pick up newly installed git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Check again
    if (-not (Test-Command git)) {
      Write-Error "[SETUP] Git installation completed but git command not found. You may need to restart your terminal."
      exit 1
    }
    
    Write-Host "[SETUP] Git installed successfully!"
  } else {
    Write-Error "[SETUP] Git is not installed and winget is not available. Please install Git manually from https://git-scm.com/"
    exit 1
  }
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
  if (-not [string]::IsNullOrWhiteSpace($currentRemote)) {
    # Normalize URLs by removing trailing .git for comparison
    $normalizedCurrent = $currentRemote -replace '\.git$', ''
    $normalizedExpected = $Remote -replace '\.git$', ''
    
    if ($normalizedCurrent -ne $normalizedExpected) {
      Write-Host "[ADOPT] Git repo exists but remote is not configured correctly."
      Write-Host "[ADOPT] Current remote: $currentRemote"
      Write-Host "[ADOPT] Expected remote: $Remote"
      $needsAdoption = $true
    }
  } else {
    Write-Host "[ADOPT] Git repo exists but has no remote configured."
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

# PULL STEP: Get current commit before pulling
$oldCommit = git -C $RepoPath rev-parse HEAD 2>$null

# Always pull latest changes
Write-Host "[PULL] Pulling updates in $RepoPath ..."
$pullOutput = git -C $RepoPath pull --rebase --autostash 2>&1 | Out-String

# Determine update status and show notification
if ($pullOutput -match "Already up to date") {
  Write-Host "[PULL] Already up to date."
  Show-Notification -StatusMessage "I'm up to date!`nReady to launch." -StatusColor "Green"
} elseif ($pullOutput -match "Fast-forward|Updating") {
  Write-Host "[PULL] Updates downloaded!"
  
  # Get new commits (limit to 3, show titles only)
  $newCommit = git -C $RepoPath rev-parse HEAD 2>$null
  $commitMessages = @()
  if ($oldCommit -and $newCommit -and $oldCommit -ne $newCommit) {
    $commits = git -C $RepoPath log --oneline --pretty=format:"%s" "$oldCommit..$newCommit" 2>$null
    if ($commits) {
      $commitLines = $commits -split "`n"
      $commitMessages = $commitLines | Select-Object -First 3
      if ($commitLines.Count -gt 3) {
        $commitMessages += "(and $($commitLines.Count - 3) more...)"
      }
    }
  }
  
  # Build message
  if ($commitMessages.Count -gt 0) {
    $commitText = $commitMessages -join "`n"
    $message = "New updates!`n`n$commitText`n`nReady to launch."
  } else {
    $message = "New updates downloaded!`nReady to launch."
  }
  
  Show-Notification -StatusMessage $message -StatusColor "Blue"
} elseif ($pullOutput -match "error|fatal|conflict") {
  Write-Host "[PULL] Error occurred during pull."
  Show-Notification -StatusMessage "Failed to update.`nCheck console for details.`n`nLaunching anyway..." -StatusColor "Red"
} else {
  Write-Host "[PULL] Pull completed."
  Show-Notification -StatusMessage "Sync complete!`nReady to launch." -StatusColor "Green"
}

# Brief status after pull
Write-Host "[PULL] Post-pull status (tracked files):"
git -C $RepoPath status -s --untracked-files=no

Write-Host "Ready to launch!"
