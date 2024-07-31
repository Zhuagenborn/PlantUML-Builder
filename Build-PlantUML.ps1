<#
.SYNOPSIS
    Send PlantUML scripts to the PlantUML server and download the built diagrams.
.PARAMETER Directory
    The directory of PlantUML scripts. It will also be used as the diagram directory. The default is the current directory.
.PARAMETER ScriptExtension
    The file extension of PlantUML scripts. The default is `puml`.
.PARAMETER Recurse
    Whether to recursively enumerate PlantUML scripts in subdirectories.
.PARAMETER File
    The name of a PlantUML script.
.PARAMETER DiagramExtension
    The file extension of built diagrams, supporting `png` and `svg`. The default is `png`.
.EXAMPLE
    PS> .\Build-PlantUML.ps1
    The script uploads all `.puml` files in the current directory to the PlantUML server, and downloads `.png` diagrams to the source directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -Recurse
    The script uploads all `.puml` files in the current directory and its subdirectories to the PlantUML server, and downloads `.png` diagrams to the source directories.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -ScriptExtension 'txt'
    The script uploads all `.txt` files in the current directory to the PlantUML server, and downloads `.png` diagrams to the source directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -DiagramExtension 'svg'
    The script uploads all `.puml` files in the current directory to the PlantUML server, and downloads `.svg` diagrams to the source directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -Directory 'docs'
    The script uploads all `.puml` files in the `docs` directory to the PlantUML server, and downloads `.png` diagrams to the source directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -File 'hello.puml'
    The script uploads the `hello.puml` file to the PlantUML server, and downloads the `hello.png` diagram to the source directory.
.EXAMPLE
    PS> .\Build-PlantUML.ps1 -File 'hello.puml' -DiagramExtension 'svg'
    The script uploads the `hello.puml` file to the PlantUML server, and downloads the `hello.svg` diagram to the source directory.
.LINK
    https://plantuml.com/en/text-encoding
#>
[CmdletBinding()]
param (
    [Parameter(ParameterSetName = 'Directory')]
    [ValidateNotNullOrWhiteSpace()]
    [string]$Directory = '.',

    [Parameter(ParameterSetName = 'Directory')]
    [ValidateNotNullOrWhiteSpace()]
    [string]$ScriptExtension = 'puml',

    [Parameter(ParameterSetName = 'Directory')]
    [switch]$Recurse,

    [Parameter(ParameterSetName = 'File', Mandatory)]
    [ValidateNotNullOrWhiteSpace()]
    [string]$File,

    [ValidateSet('png', 'svg')]
    [string]$DiagramExtension = 'png'
)

<#
.SYNOPSIS
    Format a PlantUML script to a hexadecimal byte string.
#>
function Format-Script {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Content
    )

    $bytes = $Content | Format-Hex
    return [System.BitConverter]::ToString($bytes.Bytes) -replace '-'
}

<#
.SYNOPSIS
    Send a PlantUML script to the PlantUML server and download the diagram.
#>
function Build-Script {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$Content,

        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$DiagramPath
    )

    New-Variable -Name 'server' -Value 'https://www.plantuml.com/plantuml' -Option Constant
    $encoded = Format-Script -Content $Content
    $url = "$server/$DiagramExtension/~h$encoded"
    Invoke-WebRequest -Uri $url -OutFile $DiagramPath
}

<#
.SYNOPSIS
    Read a PlantUML script file and build the diagram.
#>
function Build-File {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [System.IO.FileInfo]$Path,

        [ValidateSet('png', 'svg')]
        [string]$DiagramExtension = 'png'
    )

    try {
        $script = Get-Content -Path $Path | Out-String
        if (![string]::IsNullOrWhiteSpace($script)) {
            $diagram = Join-Path $Path.Directory "$($Path.BaseName).$DiagramExtension"
            Build-Script -Content $script -DiagramPath $diagram
            Write-Verbose "'$Path' has been built to '$diagram'."
        }
    } catch {
        Write-Host $_ -ForegroundColor Red
    }
}

if ($File) {
    Build-File -Path $File -DiagramExtension $DiagramExtension
} else {
    foreach ($file in Get-ChildItem -Recurse:$Recurse -Path (Join-Path $Directory '*') -Include "*.$ScriptExtension" ) {
        Build-File -Path $file -DiagramExtension $DiagramExtension
    }
}