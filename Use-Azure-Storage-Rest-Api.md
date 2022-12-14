# Example for using the Azure Storage REST API

This example shows how to use the Azure Storage REST API in order to work with containers and blobs with an Azure Storage Account.

## Assumptions

Before we start, let's check the following assumptions and make sure they are in place for the testing.

- Service Principal is created
- Application ID is known
- Application secret is known
- Tenant ID is known
- The corresponding Azure Storage permissions are assigned to the service principal

## Acquire an Azure AD Token

At first, we would need to acquire a token from Azure AD.

```powershell
$requestMethod  = 'POST'
$requestHeaders = @{
    'Content-Type'  = 'application/x-www-form-urlencoded'
}
$requestUri     = 'https://login.microsoftonline.com/TENANT_ID/oauth2/v2.0/token'
$requestBody    = @{
    client_id       = 'APPLICATION_ID'
    grant_type      = 'client_credentials'
    client_secret   = 'APPLICATION_SECRET'
    scope           = 'https://STORAGEACCOUNTNAME.blob.core.windows.net/.default'
}

$request = Invoke-RestMethod -Method $requestMethod `
                             -Headers $requestHeaders `
                             -Uri $requestUri `
                             -Body $requestBody
```

The `$request` variable will then hold the relevant token information.

```powershell
$request

token_type expires_in ext_expires_in access_token
---------- ---------- -------------- ------------
Bearer           3599           3599 eyJ0eXAiO...
```

This will be used for the `Authentication` header in subsequent requests. Please note that the `Authorization` header needs to follow the Bearer authentication scheme (i.E. `Authorization: Bearer TOKENVALUE`) as outlined in the corresponding RFC section [Authorization Request Header Field](https://datatracker.ietf.org/doc/html/rfc6750#section-2.1).

## Create a Container

Using the token we can now create a container (for example).

```powershell
$containerName      = 'mycontainer'
$requestUri         = 'https://STORAGEACCOUNTNAME.blob.core.windows.net/'+$containerName+'?restype=container'
$requestMethod      = 'PUT'
$requestHeaders     = @{
    'Content-Type'  = 'application/xml'
    Authorization   = $($request.token_type + ' ' + $request.access_token)
    'x-ms-date'     = $(Get-Date -AsUTC -Format 'ddd, dd MMM yyyy HH:mm:ss') + ' GMT'
    'x-ms-version'  = '2021-04-10'
}

Invoke-RestMethod -Method $requestMethod -Headers $requestHeaders -Uri $requestUri
```

## List Containers

If all went well we should now be able to see the newly created container in the list.

```powershell
$requestUri         = 'https://STORAGEACCOUNTNAME.blob.core.windows.net?restype=container&comp=list'
$requestMethod      = 'GET'
$requestHeaders     = @{
    'Content-Type'  = 'application/xml'
    Authorization   = $($request.token_type + ' ' + $request.access_token)
    'x-ms-date'     = $(Get-Date -AsUTC -Format 'ddd, dd MMM yyyy HH:mm:ss') + ' GMT'
    'x-ms-version'  = '2021-04-10'
}

$r              = ''
$r              = Invoke-RestMethod -Method $requestMethod -Headers $requestHeaders -Uri $requestUri
$bomutf8        = [system.text.Encoding]::UTF8.GetPreamble()
[xml]$return    = $r.remove(0,$bomutf8.length)

$return.EnumerationResults.Containers
```

## Create Blob

```powershell
$containerName      = 'mycontainer'
$blobName           = 'anotherblob.txt'
$requestUri         = 'https://STORAGEACCOUNTNAME.blob.core.windows.net/'+$containerName+'/'+$blobName
$requestMethod      = 'PUT'
$requestHeaders     = @{
    'Content-Type'                  = 'text/plain; charset=UTF-8'
    Authorization                   = $($request.token_type + ' ' + $request.access_token)
    'x-ms-date'                     = $(Get-Date -AsUTC -Format 'ddd, dd MMM yyyy HH:mm:ss') + ' GMT'
    'x-ms-version'                  = '2021-04-10'
    'x-ms-blob-content-disposition' = 'attachment; filename="'+$blobName+'"'
    'x-ms-blob-type'                = 'BlockBlob'
    'x-ms-access-tier'              = 'Hot'
}
$requestBody        = Get-Content $blobName

Invoke-RestMethod -Method $requestMethod -Headers $requestHeaders -Uri $requestUri -Body $requestBody
```

## List Blobs

Listing the blobs is then pretty similar to listing containers.

```powershell
$containerName      = 'mycontainer'
$requestUri         = 'https://STORAGEACCOUNTNAME.blob.core.windows.net/'+$containerName+'?restype=container&comp=list'
$requestMethod      = 'GET'
$requestHeaders     = @{
    'Content-Type'  = 'application/xml'
    Authorization   = $($request.token_type + ' ' + $request.access_token)
    'x-ms-date'     = $(Get-Date -AsUTC -Format 'ddd, dd MMM yyyy HH:mm:ss') + ' GMT'
    'x-ms-version'  = '2021-04-10'
}

$r              = ''
$r              = Invoke-RestMethod -Method $requestMethod -Headers $requestHeaders -Uri $requestUri
$bomutf8        = [system.text.Encoding]::UTF8.GetPreamble()
[xml]$return    = $r.remove(0,$bomutf8.length)

$return.EnumerationResults.Blobs
```

## Read Blobs

```powershell
$blobRequestMethod  = 'GET'
$blobRequestHeaders = @{
    'Content-Type'  = 'application/xml'
    Authorization   = $($request.token_type + ' ' + $request.access_token)
    'x-ms-date'     = $(Get-Date -AsUTC -Format 'ddd, dd MMM yyyy HH:mm:ss') + ' GMT'
    'x-ms-version'  = '2021-04-10'
}
$blobRequestUri     = $storageAccountBlobEndpoint + $containerName + '/' + $blobName

$blobRequest        = Invoke-RestMethod -Method $blobRequestMethod -Headers $blobRequestHeaders -Uri $blobRequestUri
```

## References

Most relevant information can be found in Microsofts REST API documentation.

|  #  | Title | URL |
| --- |  ---  | --- |
| 1 | Blob service REST API | https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api |
| 2 | Authorize with Azure Active Directory | https://docs.microsoft.com/en-us/rest/api/storageservices/authorize-with-azure-active-directory | 
| 3 | Representation of date/time values in headers | https://docs.microsoft.com/en-us/rest/api/storageservices/representation-of-date-time-values-in-headers |
| 4 | Versioning for the Azure Storage services | https://docs.microsoft.com/en-us/rest/api/storageservices/versioning-for-the-azure-storage-services |
| 5 | RFC 6750 | https://datatracker.ietf.org/doc/html/rfc6750 |  
