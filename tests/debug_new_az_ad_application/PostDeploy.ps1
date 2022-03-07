Write-Verbose "Create Azure AD Application" -Verbose

# Run Time Params
$ResourceGroupName = 'myAvdWorkFlowCall371231'

# Gloabl Envs
$AutomationAppName = 'avd-scaling-autoaccount'
$TenantName = 'y3qjt'
$TenantId = '98f3e5a8-1add-4955-a7ed-16b948862dbb'

# Vars
$ExpiryInMonths=60
$AutomationAccountName = $AutomationAppName + $(get-date -format "yyyyMMddhhmm")
$AutomationAccountSecretName =  "{0}-Secret" -f $AutomationAppName
$app_uri = $("http://{0}.onmicrosoft.com/{1}" -f $TenantName, $AutomationAccountName )


# Login
# Connect-AzAccount -Tenant '98f3e5a8-1add-4955-a7ed-16b948862dbb' -SubscriptionId 'b0c05537-02c7-4099-b9af-ab0702d33d39'

# Get or Create Secret from Key Vault
$KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName
$KeyVaultName =$KeyVault.VaultName
$AutomationAccountSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $AutomationAccountSecretName
if (-not $AutomationAccountSecret) {
    Write-Verbose ("No secret '{0}' found in key vault '{1}'. Generating new." -f $AutomationAccountSecretName, $KeyVaultName) -Verbose
    $NewSecret = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((New-Guid)))) + "="
    $SecurePassword = ConvertTo-SecureString $NewSecret -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $AutomationAccountSecretName -SecretValue $SecurePassword
}
else {
    Write-Verbose ("Secret '{0}' found in key vault '{1}'." -f $AutomationAccountSecretName, $KeyVaultName) -Verbose
    $automationAccountPassword = $AutomationAccountSecret.SecretValue
    
}

$plainText = ConvertFrom-SecureString $AutomationAccountSecret.SecretValue -AsPlainText

Write-Host "plainText $plainText "

$startDate = Get-Date
$endDate = $startDate.AddMonths($ExpiryInMonths) 
$passwordCredential = @{
    DisplayName         = "rbac"
    EndDateTime         = $endDate
    # KeyId               = $AutomationAccountSecretName
    StartDateTime       = $startDate
    SecretText          = $plainText
}

# $credentials = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{
#     DisplayName         = "rbac"
#     EndDateTime         = $endDate
#     StartDateTime       = $startDate
#     Password          = $plainText
# }

# New-AzADSpCredential -ObjectId $azureAdApplication.id -StartDate $startDate -EndDate $endDate -PasswordCredential $passwordCredential

# <IMicrosoftGraphPasswordCredential

# Create the Azure AD app
# $azureAdApplication = New-AzADApplication -DisplayName $AutomationAccountName -HomePage $app_uri -IdentifierUris $app_uri 
# Write-Verbose "application $azureAdApplication" - Verbose


# ApplicationId is AppId of Application object which is different from directory id in Azure AD.
# $appCredetials = New-AzADAppCredential -ObjectId $azureAdApplication.id   -StartDate $startDate -EndDate $endDate

# echo $appCredetials 

# # Create Service Principal for app
$servicePrincipal = New-AzADServicePrincipal -DisplayName $AutomationAccountName  -PasswordCredential $passwordCredential 
