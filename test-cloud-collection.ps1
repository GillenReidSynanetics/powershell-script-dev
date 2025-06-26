$jsonPath = "C:\Users\GillenReid\Downloads\02Q.Capability.json"
$capabilityStatement = Get-Content -Path $jsonPath -raw | ConvertFrom-Json

$customer = $capabilityStatement.meta.tag.display
$fhirStoreVersion = $capabilityStatement.entry.resource.version 
write-host "Client ID: $customer" -ForegroundColor Green
write-host "FHIR Store Version: $fhirStoreVersion Customer $customer" -ForegroundColor Green