

# . \home\brlamore\src\avd_automation\WVD\OrchestrationSources\SharedDeploymentFunctions\AutoAccount\New-RunAsAccount.ps1
# . \\wsl$\Ubuntu-18.04\home\brlamore\src\avd_automation\WVD\OrchestrationSources\SharedDeploymentFunctions\AutoAccount\New-RunAsAccount.ps1
. \\wsl$\Ubuntu-18.04\home\brlamore\src\avd_automation\WVD\OrchestrationSources\SharedDeploymentFunctions\AutoAccount\Get-PasswordCredential.ps1

Write-Verbose "################################" -Verbose
Write-Verbose "## 1 - DO IT ##" -Verbose
Write-Verbose "################################" -Verbose

$Guid = New-Guid

# $PasswordCredential = New-Object -TypeName Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential
# this is the same end-date which gets created when you manually create a key with "never expires" in the Azure portal
[datetime]$EndDate = "2299-12-31"
[datetime]$StartDate = Get-Date
Write-Output( $StartDate.toString() )
Write-Output( $EndDate.toString() )
Write-Output( $Guid )
$Password = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid)))) + "="
Write-Output($Password)

return $PasswordCredential
