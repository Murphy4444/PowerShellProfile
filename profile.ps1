#region Variables
$PROFILEDIR = Split-Path $PROFILE -Parent
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
        $GitInformation = Get-GitRepoInformation
        $Remote = $GitInformation.Remote
        if ($null -eq $Remote) { $Remote = "-" }
        " [$Remote/$($GitInformation.Branch)]"
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
    if ($GitInformation.Status -eq "Red") {
        Write-Host "$GitString" -ForeGroundColor Red
    }
    else {
        Write-Host "$GitString" -ForeGroundColor Green
    }
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

function Get-GitRepoInformation {
    $GitDirRelPath = Test-GitFolder
    if (!$GitDirRelPath) {
        return $false
    }
    $GitDirAbsPath = $GitDirRelPath | Resolve-Path
    $Branch = ((Get-Content "$GitDirRelPath/HEAD") -split "\/")[-1]
    $config = Get-Content "$GitDirRelPath/config"

    $RemoteIndex = [Array]::LastIndexOf($config, "[branch `"$Branch`"]") + 1
    $Remote = $config[$RemoteIndex].Replace("remote =", "").Trim()
    $URLIndex = [Array]::LastIndexOf($config, "[remote `"$Remote`"]") + 1
    $URL = $config[$URLIndex].Replace("url =", "").Trim()
    $RepoName = ($URL -split "\/")[-1] -replace "\.git"
    if ($config -notcontains "[branch `"$Branch`"]") { $Remote = $null }

    $GitStatus = Invoke-Expression "git status"

    $Status = if ($GitStatus -like "*Changes not staged for commit*" -or $GitStatus -contains "*Untracked files:*") { "Red" } else { "Green" }

    return New-Object -TypeName psobject -Property @{
        Branch    = $Branch
        Remote    = $Remote
        URL       = $URL
        Name      = $RepoName
        Directory = $GitDirAbsPath
        Status    = $Status
    }
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

function l { Get-ChildItem @args | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }
function ll { Get-ChildItem @args -Force | Sort-Object -Descending PSISContainer, @{Expression = 'Name'; Descending = $false } }

function sudo {
    Start-Process @args -Verb Runas
}


function Get-WiFiPassword {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SSID
    )
    netsh wlan show profile $SSID key=clear
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

# Load Version-Specific functions
# This looks a little malicious and prone to lead to bad things
$PSv7ScriptsFolder = "$PROFILEDIR\Scripts\PSv7\"
if ($PSVersionTable.PSVersion.Major -ge 7 -and (Test-Path $PSv7ScriptsFolder)) { 
    $Allv7ScriptFiles = Get-ChildItem "$PSv7ScriptsFolder\*.ps1"
    ForEach ($ScriptFile in $Allv7ScriptFiles) {
        . $ScriptFile.FullName
    }
}
