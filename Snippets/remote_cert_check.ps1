<#
.SYNOPSIS
    Retrieves the SSL/TLS certificate from a remote server.

.DESCRIPTION
    This script connects to a specified remote server over a specified port (default is 443 for HTTPS)
    and retrieves the SSL/TLS certificate presented by the server. The certificate can be returned in
    either raw X509Certificate2 format or as a base64-encoded string.

.PARAMETER ComputerName
    The hostname or IP address of the server from which to retrieve the certificate.

.PARAMETER port
    The port to connect to on the remote server. Default is 443.

.PARAMETER as
    Specifies the output format of the certificate. Valid values are 'base64' and 'x509certificate'.
    Default is 'x509certificate'.

.EXAMPLE
    PS> get-remotecertificate -ComputerName "example.com"
    Retrieves the SSL/TLS certificate from example.com on port 443 and returns it as an X509Certificate2 object.

.EXAMPLE
    PS> get-remotecertificate -ComputerName "example.com" -port 8443 -as "base64"
    Retrieves the SSL/TLS certificate from example.com on port 8443 and returns it as a base64-encoded string.

#>
using namespace System.Net.Sockets # Enables working with low-level socket connections
using namespace System.Net.Security # Enables secure communications over SSL/TLS
using namespace System.Security.Cryptography.X509Certificates # Provides tools for working with X.509 certificates

# Converts an X.509 certificate object into a different format or processes it (currently returns the certificate as-is)
function convertfrom-x509certificate {
    param (
        [parameter(ValueFromPipeline=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert # Input certificate of type X509Certificate2
    )
    
    process {
        $cert # Output the certificate (can be extended for more processing)
    }
}

# Retrieves the SSL/TLS certificate from a remote server
function get-remotecertificate {
    param (
        [alias('CN')] # Alias for ComputerName parameter, shorthand for usage
        [Parameter(mandatory=$true, position = 0)]
        [string]$ComputerName, # The hostname or IP address of the server
    
        [Parameter(position = 1)]
        [uint16]$port = 443, # The port to connect to (default is 443 for HTTPS)

        [validateset('base64', 'x509certificate')] # Restricts the valid values for the output format
        [string]$as = 'X509Certificate' # Output format: 'base64' or raw 'X509Certificate'
    )

    # Create a TCP client to connect to the server on the specified port
    $tcpclient = [TcpClient]::new($ComputerName, $port)
    try {
        # Wrap the TCP stream in an SSL stream to handle secure communication
        $tcpclient = [SslStream]::new($tcpclient.GetStream())
        # Authenticate the SSL connection with the server
        $tcpclient.AuthenticateAsClient($ComputerName)

        # Check the output format and process the certificate accordingly
        if ($as -eq 'base64') {
            return $tcpclient.RemoteCertificate | convertfrom-x509certificate # Convert to Base64 format (currently unprocessed)
        }

        return $tcpclient.RemoteCertificate -as [X509Certificate2] # Return the raw X509Certificate2 object
    }
    finally {
        # Clean up resources to prevent memory leaks
        if ($tcpclient -is [IDisposable]) { $tcpclient.Dispose() }
    }
}
