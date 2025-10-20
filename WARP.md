# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Git-managed Minecraft modpack for PrismLauncher (1.21.1 + Fabric 0.17.3). The primary workflow involves adding/removing mods and creating changelog-style commit messages that appear in the pre-launch notification window.

## Primary Tasks

### Adding Mods
```powershell
# Download mod .jar files to minecraft/mods/
# Stage and commit with descriptive changelog message
git add minecraft/mods/new-mod-name.jar
git commit -m "Added ExampleMod v2.1.0 - Quality of life improvements"
git push
```

### Removing Mods
```powershell
# Remove mod file and commit
git rm minecraft/mods/old-mod-name.jar
git commit -m "Removed OldMod - Causing crashes with other mods"
git push
```

### Updating Mods
```powershell
# Replace old version with new, stage both changes
git add minecraft/mods/
git commit -m "Updated TechMod v1.2.0 → v1.3.1 - New machines and bug fixes"
git push
```

## Commit Message Style

Commit messages appear in the RGB notification window before game launch, so write them as **user-friendly changelogs**:

**Good examples:**
- `Added JEI v15.2.0 - Recipe browser and item search`
- `Updated Sodium v0.5.8 → v0.6.0 - Better performance on AMD GPUs`
- `Removed OptiFine - Conflicts with Fabric rendering mods`
- `Added Create v0.5.1 - Mechanical engineering and automation`
- `Hotfix: Downgraded FabricAPI to v0.92.1 - Fixes startup crash`

**Avoid:**
- Generic messages like "update mods" or "mod changes"
- Technical jargon players won't understand
- Commit hashes or internal references

## Secondary Tasks

### Script Updates
When modifying `scripts/pull-before-launch.ps1`:
```powershell
git add scripts/pull-before-launch.ps1
git commit -m "Updated launcher script - Fixed notification timing issue"
git push
```

### Instance Configuration
When updating `instance.cfg` or `mmc-pack.json`:
```powershell
git add instance.cfg
git commit -m "Increased memory allocation to 16GB for better performance"
git push
```

## Common Commands

### Check Current Mods
```powershell
Get-ChildItem minecraft\mods\ | Select-Object Name, Length | Sort-Object Name
```

### View Recent Changelog
```powershell
# Shows what users see in the notification window
git log --oneline -5 --pretty=format:"%s"
```

### Test Sync Script
```powershell
# Test the pre-launch script manually
pwsh -NoProfile -ExecutionPolicy Bypass -File "scripts\pull-before-launch.ps1"
```

## Architecture Notes

- **Synced**: Only `minecraft/mods/` directory and management scripts
- **Local**: All configs, saves, worlds, caches stay on individual machines  
- **Notification System**: Commit messages are displayed in the custom splash window with RGB effects
- **Auto-sync**: Users get updates automatically when launching the game
- **Git LFS**: Consider enabling for very large mod files (>100MB)

## Mod Sources

When adding mods, prefer official sources:
- **CurseForge**: Most reliable, use CF project IDs when possible
- **Modrinth**: Alternative with good Fabric support  
- **GitHub Releases**: For development/beta versions
- Always verify Minecraft 1.21.1 + Fabric compatibility