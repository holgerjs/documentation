## Azure: Retrieve an OAuth2 Token through PowerShell

When working with REST APIs you'd need a Bearer Token quite often. Here is how to retrieve it through PowerShell for a Service Principal.

```powershell
function Get-AzOauth2Token
{
    [CmdletBinding()]
    Param
    (
        [string]$TenantId,
        [string]$AppId,
        [string]$Secret
    )

    $result         =   Invoke-RestMethod -Uri $('https://login.microsoftonline.com/'+$TenantId+'/oauth2/token?api-version=1.0') -Method Post -Body @{"grant_type" = "client_credentials"; "resource" = "https://management.core.windows.net/"; "client_id" = "$AppId"; "client_secret" = "$Secret" }
    $authorization  =   ("{0} {1}" -f $result.token_type, $result.access_token)
    return $authorization
}
```

Example:

```powershell
$token = Get-AzOauth2Token -TenantId tenant_id -AppId app_id -Secret secret_value
```
