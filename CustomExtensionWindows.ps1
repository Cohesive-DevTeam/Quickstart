Invoke-WebRequest -Uri https://swupdate.openvpn.org/community/releases/OpenVPN-2.5.0-I601-amd64.msi -OutFile "C:\ovpn.msi"

Start-Process -FilePath "C:\ovpn.msi" -ArgumentList "ADDLOCAL=OpenVPN.Service,OpenVPN,Drivers,Drivers.Wintun /qn" 

Start-Sleep -s 120

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

function Ignore-SelfSignedCerts
{
try
{
Write-Host "Adding TrustAllCertsPolicy type." -ForegroundColor White
Add-Type -TypeDefinition @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy
{
public bool CheckValidationResult(
ServicePoint srvPoint, X509Certificate certificate,
WebRequest request, int certificateProblem)
{
return true;
}
}
"@
Write-Host "TrustAllCertsPolicy type added." -ForegroundColor White
}
catch
{
Write-Host $_ -ForegroundColor "Yellow"
}
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
Ignore-SelfSignedCerts;

$ip1 = "10.10.10.10"
$user = "api"
$pass = "VNS3Controller-10.10.10.10"
$pair = "${user}:${pass}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add( "Authorization", $basicAuthValue )
$headers.Add( "Accept", "application/octet-stream" )

$clientpack1 = "100_127_255_193"

function Await-Api
{
while($apistatus.StatusCode -ne 200)
{
  $apistatus = Invoke-WebRequest -Uri https://"$ip1":8000/api/config -UseBasicParsing -Headers $Headers -ContentType "application/json" -Method GET -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 30
  }
}
Await-Api; 


Invoke-WebRequest -Uri https://"$ip1":8000/api/clientpack?name=$clientpack1"&"fileformat=ovpn -UseBasicParsing -Headers $Headers -ContentType "application/json" -Method GET -o "c:\Program Files\OpenVPN\config-auto\$clientpack1.ovpn"

Start-Service -Name "OpenVPNService"
