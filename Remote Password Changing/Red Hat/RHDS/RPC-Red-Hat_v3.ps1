<#  
.SYNOPSIS  
    Script to change the password of an LDAP user account in Red Hat Directory Server

.DESCRIPTION  
    Connects to the RHDS LDAP server over a secure connection, updates a user's password. 
#>

# ========================
# Configuration Variables
# ========================

$ldapport = 636                  # Change port if necessary (636 for LDAPS, 389 for LDAP)
$useSSL = $true                  # Change to $false if not using SSL
$debug = $false                  # Change to $true to enable debug output
$logFile = "ldap_debug.log"      # Log file for detailed SSL information
$acceptAllCerts = $true          # Change to $false to enforce certificate validation

# Assigning arguments
$ldaphost = $args[0]
$adminUser = $args[1]
$adminPassword = $args[2]
$userDN = $args[3]
$newPassword = $args[4]

# Enable debug output if requested
if ($debug) {
    $DebugPreference = "Continue"
    $VerbosePreference = "Continue"
}

# ========================
# Helper Functions
# ========================

function Write-DebugInfo {
    param([string]$Message)
    if ($debug) {
        Write-Host "[DEBUG] $Message"
    }
}

function Write-LogInfo {
    param([string]$Message)
    if ($debug) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

function Test-SSLHandshake {
    param([string]$ServerName, [int]$Port)
    
    Write-LogInfo "=== Independent SSL Handshake Test ==="
    Write-DebugInfo "Testing SSL handshake independently"
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient($ServerName, $Port)
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, {
            param($sslSender, $certificate, $chain, $sslPolicyErrors)
            
            Write-LogInfo "SSL Validation Callback Triggered"
            Write-LogInfo "SSL Policy Errors: $sslPolicyErrors"
            
            if ($chain) {
                Write-LogInfo "Certificate Chain Status:"
                $chain.ChainStatus | ForEach-Object { 
                    Write-LogInfo "  Status: $($_.Status)"
                    Write-LogInfo "  Details: $($_.StatusInformation)"
                }
                Write-LogInfo "Chain Elements Count: $($chain.ChainElements.Count)"
            }
            
            if ($certificate) {
                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificate)
                Write-LogInfo "Independent Test Certificate Details:"
                Write-LogInfo "  Subject: $($cert.Subject)"
                Write-LogInfo "  Issuer: $($cert.Issuer)"
                Write-LogInfo "  Valid From: $($cert.NotBefore)"
                Write-LogInfo "  Valid To: $($cert.NotAfter)"
                Write-LogInfo "  Thumbprint: $($cert.Thumbprint)"
            }
            
            return $true  # Accept to continue testing
        })
        
        Write-LogInfo "Attempting SSL authentication as client"
        $sslStream.AuthenticateAsClient($ServerName)
        Write-LogInfo "Independent SSL handshake successful"
        Write-LogInfo "SSL Protocol: $($sslStream.SslProtocol)"
        Write-LogInfo "Cipher Algorithm: $($sslStream.CipherAlgorithm)"
        Write-LogInfo "Hash Algorithm: $($sslStream.HashAlgorithm)"
        Write-LogInfo "Key Exchange Algorithm: $($sslStream.KeyExchangeAlgorithm)"
        
        $sslStream.Close()
        $tcpClient.Close()
        
        return $true
    }
    catch {
        Write-LogInfo "Independent SSL handshake failed:"
        Write-LogInfo "Exception Type: $($_.Exception.GetType().Name)"
        Write-LogInfo "Exception Message: $($_.Exception.Message)"
        Write-LogInfo "Full Exception: $($_.Exception.ToString())"
        if ($_.Exception.InnerException) {
            Write-LogInfo "Inner Exception: $($_.Exception.InnerException.ToString())"
        }
        return $false
    }
    finally {
        if ($tcpClient) { $tcpClient.Close() }
    }
}

function Test-TLSVersions {
    param([string]$ServerName, [int]$Port)
    
    Write-LogInfo "=== TLS Version Testing ==="
    Write-DebugInfo "Testing different TLS versions"
    
    $tlsVersions = @(
        @{Name="TLS 1.2"; Version=[System.Security.Authentication.SslProtocols]::Tls12},
        @{Name="TLS 1.3"; Version=[System.Security.Authentication.SslProtocols]::Tls13},
        @{Name="TLS 1.1"; Version=[System.Security.Authentication.SslProtocols]::Tls11},
        @{Name="TLS 1.0"; Version=[System.Security.Authentication.SslProtocols]::Tls}
    )

    foreach ($tls in $tlsVersions) {
        Write-LogInfo "Testing $($tls.Name)"
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient($ServerName, $Port)
            $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream())
            $sslStream.AuthenticateAsClient($ServerName, $null, $tls.Version, $false)
            Write-LogInfo "$($tls.Name): SUCCESS"
            $sslStream.Close()
            $tcpClient.Close()
        } catch {
            Write-LogInfo "$($tls.Name): FAILED - $($_.Exception.Message)"
        }
    }
}

Write-DebugInfo "Starting RHDS Password Change Script"
Write-DebugInfo "LDAP Host: $ldaphost"
Write-DebugInfo "LDAP Port: $ldapport"
Write-DebugInfo "Using SSL: $useSSL"
Write-DebugInfo "Admin User: $adminUser"
Write-DebugInfo "Target User DN: $userDN"

Write-LogInfo "=== LDAP Debug Session Started ==="
Write-LogInfo "LDAP Host: $ldaphost"
Write-LogInfo "LDAP Port: $ldapport"
Write-LogInfo "Using SSL: $useSSL"
Write-LogInfo "Admin User: $adminUser"
Write-LogInfo "Target User DN: $userDN"

# ========================
# Script Execution
# ========================

Write-DebugInfo "Starting RHDS Password Change Script"
Write-LogInfo "=== LDAP Debug Session Started ==="
Write-LogInfo "LDAP Host: $ldaphost"
Write-LogInfo "LDAP Port: $ldapport"
Write-LogInfo "Using SSL: $useSSL"
Write-LogInfo "Accept All Certs: $acceptAllCerts"
Write-LogInfo "Admin User: $adminUser"
Write-LogInfo "Target User DN: $userDN"

# Pre-connection SSL testing if SSL is enabled
if ($useSSL) {
    Write-DebugInfo "SSL enabled - performing comprehensive SSL testing"
    
    # Test basic network connectivity
    Write-LogInfo "=== Network Connectivity Test ==="
    try {
        $tcpTest = New-Object System.Net.Sockets.TcpClient($ldaphost, $ldapport)
        $tcpTest.Close()
        Write-LogInfo "Network connectivity: SUCCESS"
    } catch {
        Write-LogInfo "Network connectivity: FAILED - $($_.Exception.Message)"
    }
    
    # Test SSL handshake independently
    Test-SSLHandshake -ServerName $ldaphost -Port $ldapport
    
    # Test different TLS versions
    Test-TLSVersions -ServerName $ldaphost -Port $ldapport
}

# Load the required assembly  
Add-Type -AssemblyName "System.DirectoryServices.Protocols"  

# Establish an LDAP connection  
Write-DebugInfo "Creating LDAP connection object"
Write-LogInfo "=== LDAP Connection Creation ==="

try {
    $ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")  
    Write-LogInfo "LDAP connection object created successfully"
} catch {
    Write-LogInfo "LDAP connection object creation failed:"
    Write-LogInfo "Full Exception: $($_.Exception.ToString())"
    exit 1
}

Write-DebugInfo "Configuring SSL options"
$ldapConnection.SessionOptions.SecureSocketLayer = $useSSL

# Custom certificate validation for debugging
$ldapConnection.SessionOptions.VerifyServerCertificate = { 
    param($connection, $certificate)
    Write-DebugInfo "SSL certificate validation triggered"
    Write-LogInfo "SSL Certificate Validation Callback Triggered"
    
    try {
        if ($certificate) {
            Write-LogInfo "Raw Certificate Data:"
            Write-LogInfo "Subject: $($certificate.Subject)"
            Write-LogInfo "Issuer: $($certificate.Issuer)"
            Write-LogInfo "Serial Number: $($certificate.GetSerialNumberString())"
            Write-LogInfo "Valid From: $($certificate.NotBefore)"
            Write-LogInfo "Valid To: $($certificate.NotAfter)"
            Write-LogInfo "Thumbprint: $($certificate.Thumbprint)"
            Write-LogInfo "Has Private Key: $($certificate.HasPrivateKey)"
            Write-LogInfo "Key Algorithm: $($certificate.PublicKey.Oid.FriendlyName)"
            Write-LogInfo "Signature Algorithm: $($certificate.SignatureAlgorithm.FriendlyName)"
        } else {
            Write-LogInfo "No certificate provided by server"
        }
    } catch {
        Write-LogInfo "Error capturing certificate details: $($_.Exception.Message)"
    }
    
    return $acceptAllCerts  # Configurable certificate acceptance
}

$ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Bind with admin credentials  
Write-DebugInfo "Attempting to bind with admin credentials"
Write-LogInfo "=== LDAP Bind Attempt ==="

try {
    $credential = New-Object System.Net.NetworkCredential($adminUser, $adminPassword)  
    
    # Detailed bind operation debug
    Write-LogInfo "=== Detailed Bind Operation Debug ==="
    Write-LogInfo "Connection Details:"
    Write-LogInfo "  Server: $($ldapConnection.Directory)"
    Write-LogInfo "  AuthType: $($ldapConnection.AuthType)"
    Write-LogInfo "  Timeout: $($ldapConnection.Timeout)"
    Write-LogInfo "  SSL Enabled: $($ldapConnection.SessionOptions.SecureSocketLayer)"
    
    Write-LogInfo "Calling Bind() with detailed exception capture..."
    $bindStart = Get-Date
    $ldapConnection.Bind($credential)
    $bindEnd = Get-Date
    $bindDuration = ($bindEnd - $bindStart).TotalMilliseconds
    
    Write-DebugInfo "Admin binding successful"
    Write-LogInfo "LDAP bind successful"
    Write-LogInfo "Bind completed successfully in $bindDuration ms"
    
} catch [System.DirectoryServices.Protocols.LdapException] {
    Write-Host "Error: LDAP Exception during bind"
    Write-LogInfo "LdapException Details:"
    Write-LogInfo "  ErrorCode: $($_.Exception.ErrorCode)"
    Write-LogInfo "  ServerErrorMessage: $($_.Exception.ServerErrorMessage)"
    Write-LogInfo "  MatchedDN: $($_.Exception.MatchedDN)"
    Write-LogInfo "  Referral: $($_.Exception.Referral)"
    Write-LogInfo "  Full Exception: $($_.Exception.ToString())"
    
    $ldapConnection.Dispose()
    exit 1
    
} catch [System.ComponentModel.Win32Exception] {
    Write-Host "Error: Win32 Exception during bind"
    Write-LogInfo "Win32Exception Details:"
    Write-LogInfo "  NativeErrorCode: $($_.Exception.NativeErrorCode)"
    Write-LogInfo "  ErrorCode: $($_.Exception.ErrorCode)"
    Write-LogInfo "  Full Exception: $($_.Exception.ToString())"
    
    $ldapConnection.Dispose()
    exit 1
    
} catch {
    Write-Host "Error: Failed to bind with admin credentials"
    Write-DebugInfo "Bind error: $($_.Exception.Message)"
    Write-DebugInfo "Error type: $($_.Exception.GetType().Name)"
    
    Write-LogInfo "LDAP Bind Failed:"
    Write-LogInfo "Exception Type: $($_.Exception.GetType().Name)"
    Write-LogInfo "Exception Message: $($_.Exception.Message)"
    Write-LogInfo "Full Exception: $($_.Exception.ToString())"
    if ($_.Exception.InnerException) {
        Write-LogInfo "Inner Exception: $($_.Exception.InnerException.ToString())"
    }
    
    # Check for specific SSL-related error patterns
    $errorMsg = $_.Exception.Message
    if ($errorMsg -like "*SSL*" -or $errorMsg -like "*certificate*" -or $errorMsg -like "*trust*") {
        Write-LogInfo "SSL-RELATED ERROR DETECTED in bind operation"
    }
    if ($errorMsg -like "*hostname*" -or $errorMsg -like "*name*") {
        Write-LogInfo "HOSTNAME VALIDATION ERROR DETECTED"
    }
    
    $ldapConnection.Dispose()
    exit 1
}

# Perform password change
Write-DebugInfo "Preparing password change request"
try {  
    # Set up the password change request  
    $modifyPasswordRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest(  
        $userDN,  
        [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace,  
        "userPassword",  
        $newPassword  
    )  

    Write-DebugInfo "Sending password change request"
    # Send the password change request  
    $response = $ldapConnection.SendRequest($modifyPasswordRequest)  
    
    Write-DebugInfo "Response received: $($response.ResultCode)"
    
    if ($response.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
        Write-Host "Password updated successfully for $userDN."  
        Write-DebugInfo "Operation completed successfully"
    } else {
        Write-Host "Password change failed with result code: $($response.ResultCode)"
        Write-DebugInfo "Error message: $($response.ErrorMessage)"
    }
}  
catch {  
    Write-Host "An error occurred during password change: $($_.Exception.Message)"  
    Write-DebugInfo "Password change error: $($_.Exception.Message)"
    Write-DebugInfo "Error type: $($_.Exception.GetType().Name)"
    
    Write-LogInfo "Password Change Failed:"
    Write-LogInfo "Full Exception: $($_.Exception.ToString())"
}  
finally {  
    # Close the connection  
    Write-DebugInfo "Cleaning up connection"
    if ($ldapConnection) {
        $ldapConnection.Dispose()  
        Write-DebugInfo "Connection disposed successfully"
        Write-LogInfo "Connection disposed"
    }
}

Write-DebugInfo "Script execution completed"
Write-LogInfo "=== LDAP Debug Session Completed ==="
if ($debug) {
    Write-Host "Debug information written to: $logFile"
}