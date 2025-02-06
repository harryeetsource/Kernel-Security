# Ensure script is running as Administrator
$adminCheck = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $adminCheck) {
    Write-Host "This script requires Administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "Disabling Incompatible Security Mitigations for VirtualBox..."

# Get VirtualBox installation path
$VBoxDir = "C:\Program Files\Oracle\VirtualBox"

# Check if VirtualBox directory exists
if (-not (Test-Path $VBoxDir)) {
    Write-Host "Error: VirtualBox installation not found at $VBoxDir"
    exit 1
}

# Get all executable files inside the VirtualBox directory
$VBoxExecutables = Get-ChildItem -Path $VBoxDir -Filter "*.exe" -Recurse

# Apply security mitigation exclusions to all VirtualBox executables
foreach ($exe in $VBoxExecutables) {
    $exePath = $exe.FullName
    Write-Host "`nDisabling mitigations for: $exePath"

    # Disable Control Flow Guard (CFG)
    Set-ProcessMitigation -Name $exePath -Disable CFG

    # Disable User-Mode CET Shadow Stack
    Set-ProcessMitigation -Name $exePath -Disable UserShadowStack

    # Disable ASLR (BottomUp, ForceRelocateImages)
    Set-ProcessMitigation -Name $exePath -Disable BottomUp
    Set-ProcessMitigation -Name $exePath -Disable ForceRelocateImages

    # Disable SEHOP
    Set-ProcessMitigation -Name $exePath -Disable SEHOP
}

# Verify applied settings for all VirtualBox executables
Write-Host "`nVerifying applied settings for VirtualBox executables..."
foreach ($exe in $VBoxExecutables) {
    Get-ProcessMitigation -Name $exe.FullName
}

Write-Host "`nConfiguration completed. Restarting VirtualBox..."
