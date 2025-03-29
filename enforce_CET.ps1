# Ensure script is running as Administrator
$adminCheck = [System.Security.Principal.WindowsPrincipal]::new([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $adminCheck) {
    Write-Host "This script requires Administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "Ensuring Full Kernel-Mode and User-Mode CET Enforcement..."

# Configure Kernel-Mode CET (Registry Change)
Write-Host "Ensuring Kernel-Mode Hardware-Enforced Stack Protection is enforced..."
$kernelKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel"
if (-not (Test-Path $kernelKey)) {
    New-Item -Path $kernelKey -Force | Out-Null
}
Set-ItemProperty -Path $kernelKey -Name "KernelModeHardwareEnforcedStackProtection" -Type DWord -Value 1

# Apply Exploit Protection Policies
Write-Host "Applying Exploit Protection Settings..."
$exploitGuardKey = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exploit Guard\System Mitigations"
if (-not (Test-Path $exploitGuardKey)) {
    New-Item -Path $exploitGuardKey -Force | Out-Null
}
$mitigations = @(
    "AuditDynamicCode",
    "AuditRemoteImageLoads",
    "AuditLowLabelImageLoads",
    "AuditUserShadowStack",
    "AuditCFG",
    "AuditSystemCall",
    "AuditDynamicCode",
    "AuditEnableImportAddressFilter",
    "AuditMicrosoftSigned",
    "AuditEnableRopCallerCheck"

)

# Loop through each mitigation and enable it using Set-ProcessMitigation
foreach ($mitigation in $mitigations) {
    Write-Host "Enabling system mitigation: $mitigation"
    try {
        Set-ProcessMitigation -System -Enable $mitigation
        Write-Host "Successfully enabled $mitigation"
    }
    catch {
        Write-Host "Failed to enable $mitigation. Error: $_"
    }
}

# Verify applied settings
Write-Host "Verifying applied settings..."
Get-ProcessMitigation -System

# Restart system to apply changes
Write-Host "Configuration completed. Restarting system in 10 seconds..."
Start-Sleep -Seconds 10
Restart-Computer -Force
