[console]::Title = "powershell compiler"
[console]::ForegroundColor = 'white'
"
		POWERSHELL COMPILER IIS GROUP

        [*] BY NATNAEL WUBET [*]
        [*] EMAIL: natyw4122@gmail.com [*]
 
"

[console]::ForegroundColor = "green"
$priv = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $priv.IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
{
    Write-Host "[error] you need administrator privelage to setup AVWKeyboard" -ForegroundColor Yellow
    exit
}
pushd $env:windir\system32\WindowsPowerShell\v1.0\Modules
if (!(Test-Path .\WebAdministration))
{
    Write-Host "[error] you need to enable IIS configuration from controlpanal-turnwindowsfeature" -ForegroundColor Yellow
    exit
}
Write-Host "[*] importing WebAdministration module" -ForegroundColor Cyan -NoNewline
try
{
    Import-Module WebAdministration
    Write-Host " [imported]" -ForegroundColor Green
} catch {
    Write-Host " [Error]:$_" -ForegroundColor Red
    exit
}
popd
Write-Host "[*] creating IISsite " -ForegroundColor Cyan -NoNewline
try
{
    foreach ($tmp in (Get-IISSite))
    {
        if ($tmp.State -eq "Started")
        {
            Stop-IISSite $($tmp.Name)
        }
    }
    $i=0 
    foreach ($tmp in ((Get-IISSite).Name))
    {
        if ($tmp -ne "PoSH_compiler_share")
        {
            $i++
        }
    }
    $count = (Get-IISSite).name
    if ($i -eq $count.count)
    {
        New-IISSite -name PoSH_compiler_share -PhysicalPath "$((pwd).Path)\share" -BindingInformation '*:80:'
        Write-Host "[created]"
    } else {
        New-IISSite -name PoSH_compiler_share -PhysicalPath "$((pwd).Path)\share" -BindingInformation '*:80:'
        Write-Host "[created]"
		#Write-Host "[already created]" -ForegroundColor Yellow
    }

} catch {
    Write-Host "[error]:$_" -ForegroundColor Red
}
Write-Host "[*] starting PoSH_compiler_share service" -ForegroundColor Cyan -NoNewline
try
{
    Start-IISSite PoSH_compiler_share
    Write-Host " [started]" -ForegroundColor Green
} catch {
    Write-Host " [error]:$_" -ForegroundColor Red
}
$scr = read-host "Script path"
if ($scr)
{
	if (test-path $scr)
	{
		write-host "[*] streaming Scripts" -nonewline
		md share |out-null
		cat $scr |out-file ./share/share.html
	
	}
}

" Done

clone http://<myip>/share.html
"
Read-Host
