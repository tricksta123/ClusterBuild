#Define Variables
$Directory = "C:\Windows\Build"
$KeyFile = Join-Path $Directory  "AES_KEY_FILE.key"
$PasswordFile = Join-Path $Directory "AES_PASSWORD_FILE.txt"

#Get Password from user prompt
$Password = Read-Host -Prompt "Enter password and press ENTER:" -AsSecureString

#Creates a 256bit AES Key and saves it to AES_KEY_FILE.key.
$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile
$KeyFileCreated = $True
Write-Host "The key file $KeyFile was created successfully"

#Uses the password from the prompt and encrypts it using the generated key. Saves the encrypted password to AES_PASSWORD_FILE.txt
$Key = Get-Content $KeyFile
$Password = $Password | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
Write-Host "The key file $PasswordFile was created successfully"
	
#To re-use the encrypted password, read in the key, then read the password file using the key to decrypt. Then create a credential using the secure string. 
$Account = "domain\user"
$Key = Get-Content "C:\windows\build\AES_KEY_FILE.key"
$securePassword = (Get-Content "C:\windows\build\AES_PASSWORD_FILE.txt" | ConvertTo-SecureString -Key $Key)
$UserCredentials = New-Object System.Management.Automation.PSCredential($Account, $securePassword)
