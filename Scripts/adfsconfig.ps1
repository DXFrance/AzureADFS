Param(
    $VMName,
    $domain, 
	$fullyQualifiedDomainName,
    $adUser,
    $adPassword,
	$serviceUri
    )

Set-ExecutionPolicy Unrestricted -Force

$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "scriptFolder" $scriptFolder
# Should be C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\Downloads\0
$ScriptBaseName = [io.path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)

start-transcript -path $scriptfolder\$ScriptBaseName.txt
		
$adSecurePassword = $adPassword | ConvertTo-SecureString -AsPlainText -Force
$domUser = $domain + "\" + $adUser
$domCreds = New-Object System.Management.Automation.PSCredential -ArgumentList $domUser, $adSecurePassword 
   
#ADFS Install
Write-Host "AD-Federation-Services Started . . ."

Install-WindowsFeature AD-Federation-Services
        
Write-Host "AD-Federation-Services Installed."
		
# Create a new Self-Signed Certificated
$adfsCert = New-SelfSignedCertificate -DnsName $serviceUri -CertStoreLocation cert:\LocalMachine\My
		
# Bind HTTPS to the default web site
New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -Protocol https
		
# Associate the cert with the SSL port 443 of the Default Web Site.
$certSubjectName = "CN=" + $serviceUri
		
cd IIS:\SslBindings
$myCert = Get-ChildItem cert:\LocalMachine\My | Where-Object{$_.Subject -match $certSubjectName} | Select-Object -First 1
$myCert | New-Item IIS:\SslBindings\0.0.0.0!443
		
Write-Host "Starting AD FS Standalone installation . . . "
		
Install-AdfsStandalone `
	-CertificateThumbprint $myCert.Thumbprint `
	-FederationServiceName $serviceUri `
	-verbose
			
	#-FederationServiceName $fullyQualifiedDomainName `
#TODO: Disable Windows Extended Protection
#http://social.technet.microsoft.com/wiki/contents/articles/1426.ad-fs-2-0-continuously-prompted-for-credentials-while-using-fiddler-web-debugger.aspx>
#		Add-PSSnapin Microsoft.Adfs.Powershell
#		Set-ADFSProperties -ExtendedProtectionTokenCheck:None
#		IISRest
#		Net Stop ADFS
#		Net Start ADFS
        
Write-Host "AD FS Standalone installation complete."