#region Variables
$PROFILEDIR = ($PROFILE -split "\\" | Select-Object -SkipLast 1) -join "\"
$PSPROFILE = "$PROFILEDIR\profile.ps1" ; $PSPROFILE | Out-Null
$env:ReplacePathPrompt = "$HOME|~"
#endregion

#region Functions
function prompt {
    $MAXFULLPATH = 5
    $Path = (Get-Location).ProviderPath

    ForEach ($KVP in ($env:ReplacePathPrompt -split ",")) {
        $Key, $Value = $KVP -split "\|"
        $Path = $Path -ireplace [regex]::Escape("$Key"), "$Value"
    }
    
    $GitFolderTest = Test-GitFolder

    $GitString = if ($GitFolderTest) {
        $Branch = ((Get-Content "$GitFolderTest/HEAD") -split "\/")[-1]
        $config = Get-Content "$GitFolderTest/config"

        $RemoteIndex = [Array]::LastIndexOf($config, "[branch `"$Branch`"]") + 1
        $Remote = $config[$RemoteIndex].Replace("remote =", "").Trim()
        if ($config -notcontains "[branch `"$Branch`"]") { $Remote = "-" }
        " [$Remote/$Branch]"
    }
    else {
        ""
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
    Write-Host "$GitString" -ForeGroundColor Green
    Write-Host ">" -NoNewLine -ForeGroundColor White
    
    return " "
}

function Test-GitFolder {
    $Path = (Get-Location).ProviderPath
    $SplitPath = $Path -split "\\" |  Where-Object { $_ -ne "" -and $_ -ne $null }
    $DotGitPath = ".git"
    
    for ($folder = $SplitPath.Count - 1; $folder -ge 0 ; $folder--) {  
        if (Test-Path $DotGitPath) { return $DotGitPath }
        $DotGitPath = "../$DotGitPath"
    }
    return $false
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

function l { param($Path, $MoreParams = ""); Invoke-Expression "Get-ChildItem $Path $MoreParams" | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }
function ll { param($Path, $MoreParams = ""); Invoke-Expression "Get-ChildItem -Force $Path $MoreParams" | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }

function sudo {
    Start-Process @args -Verb Runas
}

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
$CompSpecPath = "$PROFILEDIR\ComputerSpecific.ps1"
if (Test-Path $CompSpecPath) {
    . $CompSpecPath
}
