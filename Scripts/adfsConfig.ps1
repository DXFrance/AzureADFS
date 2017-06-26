#Import-Module ADFS

Param(
    $VMName,
    $domain, 
	$fullyQualifiedDomainName,
    $adUser,
    $adPassword,
	$serviceUri
    )

#region LocalTests
#Param(
#$VMName="SENSORIT-ADFS0",
#$domain="SENSORIT", 
#$fullyQualifiedDomainName="sensorit.cloud",
#$adUser="AzureAdmin",
#$adPassword="Pass@word1!?",
#$serviceUri="sensorit-adfs.westeurope.cloudapp.azure.com"
#)
#endregion

Set-ExecutionPolicy Unrestricted -Force


$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "scriptFolder" $scriptFolder

$SelfSignedCertificateExFunctionPath = "$scriptfolder\New-SelfSignedCertificateEx.ps1"

#Import function
. $SelfSignedCertificateExFunctionPath

# Should be C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\Downloads\0
$ScriptBaseName = [io.path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)

start-transcript -path $scriptfolder\$ScriptBaseName.txt
		
$adSecurePassword = $adPassword | ConvertTo-SecureString -AsPlainText -Force
$domUser = $domain + "\" + $adUser
$domCreds = New-Object System.Management.Automation.PSCredential -ArgumentList $domUser, $adSecurePassword 
   
#ADFS Install

#-WindowsFeature AD-Federation-Services
#Install-WindowsFeature adfs-federation -IncludeManagementTools
        
Write-Host "AD-Federation feature Installed."
		
# Create a new Self-Signed Certificated"

New-SelfSignedCertificateEx -Subject "CN=$serviceUri" -EKU "Server Authentication" -KeyUsage 160 -StoreLocation "LocalMachine" `
                            -ProviderName "Microsoft Strong Cryptographic Provider" -Exportable


$adfsCertThumbprint = (get-childitem "cert:\localmachine\my" | where { $_.subject -eq "CN=$serviceUri" }).Thumbprint
Write-Host $adfsCertThumbprint


#Import-Module ServerManager
#Install-WindowsFeature -Name Web-Server, Web-WebServer, Web-Mgmt-Tools

	
# Bind HTTPS to the default web site
#New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -Protocol https
		
# Associate the cert with the SSL port 443 of the Default Web Site.
#$certSubjectName = "CN=" + $serviceUri
		

#$myCert = Get-ChildItem cert:\LocalMachine\My | Where-Object{$_.Subject -match "CN=$serviceUri"} | Select-Object -First 1
#cd IIS:\SslBindings
#$myCert | New-Item IIS:\SslBindings\0.0.0.0!443
		
Write-Host "Starting AD FS Standalone installation . . . "

#On the DC
#Add-KdsRootKey –EffectiveTime (Get-Date).AddHours(-10)

#Install-AdfsFarm -CertificateThumbprint $adfsCertThumbprint -FederationServiceName $serviceUri -GroupServiceAccountIdentifier $domUser$ -verbose
Install-AdfsFarm -CertificateThumbprint $adfsCertThumbprint -FederationServiceName $serviceUri -ServiceAccountCredential $domCreds -verbose
		
#Install-AdfsStandalone `
#	-CertificateThumbprint $adfsCertThumbprint `
#	-FederationServiceName $serviceUri `
#	-verbose
			
	#-FederationServiceName $fullyQualifiedDomainName `
#TODO: Disable Windows Extended Protection
#http://social.technet.microsoft.com/wiki/contents/articles/1426.ad-fs-2-0-continuously-prompted-for-credentials-while-using-fiddler-web-debugger.aspx>
#		Add-PSSnapin Microsoft.Adfs.Powershell
#		Set-ADFSProperties -ExtendedProtectionTokenCheck:None
#		IISRest
#		Net Stop ADFS
#		Net Start ADFS
        
Write-Host "AD FS Standalone installation complete."
stop-transcript