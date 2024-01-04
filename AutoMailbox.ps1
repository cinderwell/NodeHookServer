Set-ExecutionPolicy RemoteSigned
$User=$args[0]
$Email=$args[1]


$CloudUsername = 'YOUR_USERNAME'
$CloudPassword = ConvertTo-SecureString 'YOUR_PASSWORD' -AsPlainText -Force
$CloudCred = New-Object System.Management.Automation.PSCredential $CloudUsername, $CloudPassword




$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri YOUR_URI -Authentication Kerberos -Credential $CloudCred
Import-PSSession $Session -DisableNameChecking


Enable-RemoteMailbox $User -RemoteRoutingAddress $Email

Remove-PSSession $Session