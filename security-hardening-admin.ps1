$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  throw "Run this script from an elevated PowerShell session (Run as Administrator)."
}

Write-Host "[1/7] Enforcing Windows Firewall defaults..."
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow

Write-Host "[2/7] Disabling Remote Assistance..."
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name fAllowToGetHelp -Type DWord -Value 0

Write-Host "[3/7] Keeping Remote Desktop disabled..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 1

Write-Host "[4/7] Disabling Network Discovery firewall rules..."
Set-NetFirewallRule -DisplayGroup 'Network Discovery' -Enabled False

Write-Host "[5/7] Disabling File and Printer Sharing firewall rules..."
Set-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -Enabled False

Write-Host "[6/7] Updating Defender signatures..."
Update-MpSignature | Out-Null

Write-Host "[7/7] Starting Defender quick scan..."
Start-MpScan -ScanType QuickScan

Write-Host ""
Write-Host "Hardening complete. Current status:"
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name fAllowToGetHelp | Select-Object fAllowToGetHelp | Format-List
Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections | Select-Object fDenyTSConnections | Format-List
