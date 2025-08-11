

<#
.SYNOPSIS
    Sends a GET request to a specified FHIR endpoint with a provided API key.

.DESCRIPTION
    This script sets up a custom certificate policy to trust all SSL certificates, prompts the user for an API key, 
    and sends a GET request to a specified FHIR endpoint with the provided API key in the headers.

.PARAMETER apiKey
    The API key to be included in the request headers for authentication.

.NOTES
    The script uses a custom certificate policy to bypass SSL certificate validation. 
    This is generally not recommended for production environments due to security risks.

.EXAMPLE
    .\curl-request.ps1
    Prompts the user to enter an API key and sends a GET request to the specified FHIR endpoint.
#>

# Set up a custom certificate policy to trust all SSL certificates
add-type @"

using http://System.Net ;

using System.Security.Cryptography.X509Certificates;

public class TrustAllCertsPolicy : ICertificatePolicy {

    public bool CheckValidationResult(

        ServicePoint srvPoint, X509Certificate certificate,

        WebRequest request, int certificateProblem) {

            return true;

        }

 }

"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$apiKey = Read-Host "Please enter the API Key"

$headers = @{

    "api-key"= $apiKey

}

Invoke-RestMethod -Method Get -Uri 'https://localhost:8443/fhir/stu3/Patient?_tag=https://yhcr.nhs.uk/pix/registration/status|error,failed' -Headers $headers