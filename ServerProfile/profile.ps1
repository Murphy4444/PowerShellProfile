#region Variables
$PROFILEDIR = Split-Path $PROFILE.CurrentUserAllHosts -Parent
$PSPROFILE = $PROFILE.CurrentUserAllHosts ; $PSPROFILE | Out-Null
$env:ReplacePathPrompt = "$HOME|~"
$env:ReplacePathPrompt += ",HKEY_LOCAL_MACHINE|HKLM:"
$env:ReplacePathPrompt += ",HKEY_CLASSES_ROOT|HKCR:"
$env:ReplacePathPrompt += ",HKEY_CURRENT_USER|HKCU:"
$env:ReplacePathPrompt += ",HKEY_USERS|HKUS:"
$env:ReplacePathPrompt += ",HKEY_CURRENT_CONFIG|HKCC:"
#endregion

#region Functions
function prompt {
    $LastCommandExecutionState = if ($?) { "Green" } else { "Red" }

    $MAXFULLPATH = 5
    $Path = (Get-Location).ProviderPath

    ForEach ($KVP in ($env:ReplacePathPrompt -split ",")) {
        $Key, $Value = $KVP -split "\|"
        $Path = $Path -ireplace [regex]::Escape("$Key"), "$Value"
    }

    $SplitPath = $Path -split "\\" |  Where-Object { $_ -ne "" -and $_ -ne $null }
    if ($SplitPath.Count -gt $MAXFULLPATH) { 
        if ($Path -like "\\*") {
            $Share = $true
            $SplitPath = $SplitPath -replace "\\\\", "\\"
        }
        $PathPrompt = ""

        if ($Share) { $PathPrompt = "\\" }
        $PathPrompt += $SplitPath[0]

        for ($i = 1; $i -le ($SplitPath.Count - $MAXFULLPATH); $i++) {
            $c = -1
            $FirstLetter = ""
            do {
                $c++
                if ($c -ge ($SplitPath[$i] -split "" | Where-Object { $_ -ne "" -and $_ -ne $null }).Count) { $c--; break; }
                $FirstLetter = ($SplitPath[$i])[$c]
            } while ([int][char]$FirstLetter -notin (65..90 + 97..122 + 228, 246, 252, 196, 214, 220))
            $PathPrompt += "\" + $(($SplitPath[$i])[0..$c] -join "")
        }
        $PathPrompt += "\"
        $PathPrompt += $SplitPath[(((-1) * $MAXFULLPATH) + 1)..-1] -join "\"
    }
    else {
        $PathPrompt = $Path
    }
    if ($PathPrompt[-1] -eq ":") {
        $PathPrompt = "$PathPrompt\"
    }

    $Version = $PSVersionTable.PSVersion
    $PSVersion = "$($Version.Major).$($Version.Minor)"
    $Time = Get-Date -UFormat "%H:%M:%S"

    # [System.Console]::Title = "$AdminString PowerShell $PSVersion"
    [System.Console]::Title = "PowerShell $PSVersion | $PathPrompt$GitString"

    # Write-Host "$AdminString" -NoNewLine -ForeGroundColor Green
    Write-Host "PS" -NoNewLine -ForeGroundColor DarkBlue
    Write-Host "$PSVersion " -NoNewLine -ForeGroundColor Blue
    Write-Host "[$Time] " -NoNewLine -ForeGroundColor Red
    Write-Host "$PathPrompt" -NoNewLine -ForeGroundColor White

    $TerminalWindowWidth = $Host.UI.RawUI.WindowSize.Width
    $LastCommand = Get-History | Select-Object -Last 1
    if ($LastCommand.Duration) {
        $LastCommandExecutionTime = $LastCommand.Duration
    }
    else {
        $LastCommandExecutionTime = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
    }

    if ($LastCommandExecutionTime.Hours) {
        $FormattedExecutiontime = "$($LastCommandExecutionTime.Hours)h $($LastCommandExecutionTime.Hours)m"
    }
    elseif ($LastCommandExecutionTime.Minutes) {
        $FormattedExecutiontime = "$($LastCommandExecutionTime.Minutes)m $($LastCommandExecutionTime.Seconds)s"
    }
    else {
        $FormattedExecutiontime = "$([System.Math]::Round($LastCommandExecutionTime.TotalSeconds,3))s"
    }

    $LastCommandString = if ($LastCommandExecutionTime.Ticks) { " $FormattedExecutiontime [ `$? ] " } else { "" }
    
    $RightAlignedPosition = New-Object System.Management.Automation.Host.Coordinates ($TerminalWindowWidth - $LastCommandString.Length), $Host.UI.RawUI.CursorPosition.Y

    $Host.UI.RawUI.CursorPosition = $RightAlignedPosition

    # $CurrentCursorPosition = $Host.UI.RawUI.CursorPosition

    if ($LastCommandExecutionTime.Ticks) { 
        Write-Host " $FormattedExecutiontime" -NoNewline
        Write-Host " [ " -NoNewline
        Write-Host "`$?" -NoNewline -ForegroundColor:$LastCommandExecutionState
        Write-Host " ]" -NoNewline
    }
 

    Write-Host "`n>" -NoNewLine -ForeGroundColor White
    
    return " "
}

function pw {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$r
    )
    if ($r) {
        Start-Process powershell -Verb Runas -ArgumentList  "-NoLogo"
    }
    else { 
        Start-Process powershell 
    }
}

function pw7 {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$r
    )
    if ($r) {
        Start-Process pwsh -Verb Runas -ArgumentList  "-NoLogo"

    }
    else { 
        Start-Process pwsh 
    }
}

function cdp {
    Set-Location $PROFILEDIR
}

function cld {
    Clear-Host
    Get-ChildItem -Force
}

function cdl {
    param($Path = $pwd)
    Set-Location $Path
    Get-ChildItem -Force
}

<#
function init {
    param (
        $param, [switch]$f
    )
    if ($f) { $ff = "-f" } else { $ff = "" }
    if ($param -eq 0) {
        shutdown -s -t 0 $ff
    }
    elseif ($param -eq 6) {
        shutdown -r -t 0 $ff
    }
}
#>

function touch ([Parameter(Mandatory = $true)]$FileNameOrPath) {
    New-Item -ItemType File $FileNameOrPath
}

function Compare-FilesInFolder { 
    param(
        $FirstFolder, 
        $SecondFolder
    ) 
    $FirstHashes = Get-ChildItem -File -Recurse $FirstFolder | ForEach-Object { (Get-FileHash $_).Hash }
    $SecondHashes = Get-ChildItem -File -Recurse $SecondFolder | ForEach-Object { (Get-FileHash $_).Hash }

    Compare-Object $FirstHashes $SecondHashes
}

function l { Get-ChildItem @args | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }
function ll { Get-ChildItem @args -Force | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }

function sudo {
    Start-Process @args -Verb Runas
}



function New-TimeSpanSum {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Times
    )
    $TotalTime = New-TimeSpan
    for ($i = 0; $i -lt $Times.count; $i += 2) {
        $TotalTime += New-TimeSpan $Times[$i] $Times[$i + 1]
    
    }
    return $TotalTime
}

function Get-Type {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Object,
        [Parameter(Mandatory = $false)]
        [switch]$FullName
    )

    $Type = $Object.Gettype()

    if ($FullName) { return $Type.FullName }
    return $Type
}

function Resolve-IPAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ipaddress]$IPAddress
    )

    return [System.Net.Dns]::GetHostByAddress($IPAddress)
}

function Restart-Explorer {
    Get-Process explorer | Stop-Process -Force
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
}

#endregion

#region PSDrives for Registry
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
New-PSDrive -Name HKUS -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
New-PSDrive -Name HKCC -PSProvider Registry -Root HKEY_CURRENT_CONFIG -ErrorAction SilentlyContinue | Out-Null

#endregion

#region Aliases
Set-Alias -Name "nts" New-TimeSpan
Set-Alias -Name "ntsm" New-TimeSpanSum
Set-Alias -Name "ntss" New-TimeSpanSum
Set-Alias -Name "gd" Get-Date
Set-Alias -Name "ex" explorer.exe
Set-Alias -Name "gt" Get-Type
Set-Alias -Name "fixex" Restart-Explorer
Set-Alias -Name "^" Select-Object
Set-Alias -Name "rip" Resolve-IPAddress
Set-Alias -Name "m" Measure-Object
#endregion
