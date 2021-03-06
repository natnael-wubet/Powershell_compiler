Add-Type -AssemblyName system.windows.forms
Add-Type -AssemblyName system.net
cls

function response ($text)
{
    [byte[]] $b = [System.Text.Encoding]::UTF8.GetBytes("$text")
    $res.ContentLength64 = $b.Length
    $out = $res.OutputStream
    $out.Write($b, 0, $b.Length)
    $out.Close()
}
$port = Read-Host "Port"
$listn = New-Object System.Net.HttpListener
$listn.Prefixes.Add("http://+:$port/")
try {
    $listn.Start()
} catch {
    [System.Windows.Forms.MessageBox]::Show("Error thrown: $($_[0])") |Out-Null
    pause
    .\web.ps1
    exit
}
. .\tmp.ps1
[console]::Title = $listn.Prefixes
while ($true)
{
    Write-Host "waiting for clients" -ForegroundColor DarkYellow -NoNewline
    $cont = $listn.GetContext()
    $req = $cont.Request
    Write-Host "[$($h = [Net.DNS]::BeginGetHostEntry($req.RemoteEndPoint.Address.IPAddressToString, $null, $null);$hostName = ([Net.DNS]::EndGetHostEntry([IAsyncResult]$h)).HostName;if (!([string]::IsNullOrEmpty($hostName))) {Write-Output $hostName} else {Write-Output $req.RemoteEndPoint.Address.IPAddressToString}) connected]" -ForegroundColor Green
    $res = $cont.Response
    if ($req.HttpMethod -eq "GET")
    {
        if ($req.RawUrl -eq "/")
        {
            if ($req.UserAgent -eq "Posh_compiler")
            {
                try {
                    $temp = $null
                    foreach ($tmp in (cat $filepath))
                    {
                        $temp += "`n$tmp"
                    }
                    response -text $temp
                    Write-Host "Script sended to the client" -ForegroundColor White
                } catch {
                    Write-Host "Error: $($_[0])" -ForegroundColor DarkCyan
                }
            }
        } elseif ($req.RawUrl -eq "/end")
        {
            $res.AddHeader('WWW-Authenticate', 'Basic')
		    $res.AddHeader("Content-Type","text/html")
            $res.AddHeader("Host","InternetGateway")
		    $res.StatusCode = 401
            try
            {
                $head = $req.Headers
                [string[]]$key = $head.GetValues('Authorization')
                $ntlm = $key[0] -split "\s+"
                $creds = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String( $ntlm[1])))
                $crds = $creds -split ":"
                . .\reg.ps1
            
                if (($crds[0] -eq $usr) -and ($crds[1] -eq $pass))
                {
                    response -text "Service Down"
                    $res.StatusCode = 404
                    $listn.Stop()
                    exit
                }
            } catch {}
            response -text "Confirm"
        }

    }
}


