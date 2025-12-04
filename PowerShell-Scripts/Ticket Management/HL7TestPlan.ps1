function Send-TCPMessage {
    Param ( 
            [Parameter(Mandatory=$true, Position=0)]
            [ValidateNotNullOrEmpty()] 
            [string] 
            $EndPoint
        , 
            [Parameter(Mandatory=$true, Position=1)]
            [int]
            $Port
        , 
            [Parameter(Mandatory=$true, Position=2)]
            [string]
            $Message
    )
    Process {
      # Setup connection
      $ip = [system.net.dns]::GetHostAddresses($EndPoint)
      $address = [System.Net.IPAddress]::Parse($ip)
      $socket = New-Object System.Net.Sockets.TcpClient($address,$Port)

      # Setup Stream Writer
      $Stream = $socket.GetStream()
      $writer = New-Object System.IO.StreamWriter($Stream)

        # Write message to stream
        $Message | % {
            $Writer.WriteLine($_)
            $Writer.Flush()
        }
        # Close connection and stream
        $Stream.Close()
        $Socket.Close()
    }
}