$certFile = Get-ChildItem -Filter *.pem | Select-Object -First 1
$keyFile = Get-ChildItem -Filter *.key | Select-Object -First 1

if (-not $certFile) {
  Write-Host "❌ No .pem file found in current directory: $PWD" -ForegroundColor Red
  return
if (-not $keyFile) {
  Write-Host "❌ No .key file found in current directory: $PWD" -ForegroundColor Red
  return
}

Write-Host "Using certificate: $($certFile.FullName)"
Write-Host "Using key: $($keyFile.FullName)"

$certHash = & openssl x509 -modulus -noout -in $certFile | openssl md5
$keyHash  = & openssl rsa  -modulus -noout -in $keyFile  | openssl md5

if ($certHash -eq $keyHash) {
  Write-Host "✅ Match confirmed!" -ForegroundColor Green
} else {
  Write-Host "❌ Certificate and key do NOT match!" -ForegroundColor Red
}
}