#region Variables
$PROFILEDIR = (Get-Item $PROFILE).Directory.FullName
#endregion

#region Functions
function prompt {
    $MAXFULLPATH = 5
    $Path = (Get-Location).ProviderPath
    $IsAdmin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544'
    $AdminString = "" ; if ($IsAdmin) { $AdminString = "↑ " } 
    $Path = $Path.Replace("$HOME", "~")
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
            } while ($FirstLetter -notmatch "[a-zA-Z0-9äöüÄÖÜ]")
            $PathPrompt += "\" + $(($SplitPath[$i])[0..$c] -join "")
        }
        $PathPrompt += "\"
        $PathPrompt += $SplitPath[(((-1) * $MAXFULLPATH) + 1)..-1] -join "\"
    }
    else {
        $PathPrompt = $Path
    }

    $Version = $PSVersionTable.PSVersion
    $PSVersion = "$($Version.Major).$($Version.Minor)"
    $Time = Get-Date -UFormat "%H:%M:%S"

    [System.Console]::Title = "$AdminString PowerShell $PSVersion"

    Write-Host "$AdminString" -NoNewLine
    Write-Host "PS" -NoNewLine -ForeGroundColor DarkBlue
    Write-Host "$PSVersion " -NoNewLine -ForeGroundColor Blue
    Write-Host "[$Time] " -NoNewLine -ForeGroundColor Red
    Write-Host "$PathPrompt>" -NoNewLine -ForeGroundColor White
    
    return " "
}

function pw {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$r
    )
    if ($r) {
        Start-Process powershell -Verb Runas 
    }
    else { 
        Start-Process powershell 
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

function l { param($Path); Get-ChildItem $Path | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }
function ll { param($Path); Get-ChildItem -Force $Path | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }

function New-Password ($Length) {
    $CharArr = @()
    $MajLet = @()
    $MinLet = @()
    65..90 | ForEach-Object { $MajLet += [char]$_ }
    97..122 | ForEach-Object { $MinLet += [char]$_ }
    $SpecChars = ".", ",", ";", "'", "\", "/", ".", ",", ";", "'", "\", "/"
    $CharArr += @(@(0..9), @($MajLet), @($MinLet), @($SpecChars))
    
    for ($i = 0; $i -lt $length; $i++) {
        Write-Host (Get-Random (Get-Random $CharArr)) -NoNewline
    }

}
#endregion

#region Aliases
Set-Alias -Name "nts" New-TimeSpan
Set-Alias -Name "gd" Get-Date
Set-Alias -Name "ex" explorer.exe

#endregion
$CompSpecPath = "$((Get-Item $PROFILE).Directory)\ComputerSpecific.ps1"
if (Test-Path $CompSpecPath) {
    . $CompSpecPath
}
