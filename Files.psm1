<# 
.Synopsis 
Files

.Description
Helper for managing files items

.Notes 
NAME  : Files.psm1*
AUTHOR: rulasg   

CREATED: 03/05/2022
#>

Write-Host "Loading Files ..." -ForegroundColor DarkCyan

#File

function Move-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)] [System.IO.FileInfo] $File,
        [string] $Path,
        [string] $Destination,
        [switch] $Test        
    )

    begin {
        Write-Verbose -Message "Move-File begin >>>" 

        $count = 0
        
        if ([string]::IsNullOrEmpty($Destination)) {
            $Destination = (Get-location).Path
        }
        Write-Verbose -Message "Move-File to Destination [$Destination]"

        if ($Path) {
            $File = Get-Item -Path $Path
        }  
        
        #Update HashTable with Destination content 
        Get-ChildItem -Path $Destination  -File | Find-HashTableDuplicates
    }
    
    process {
        $count++
        $p = $count%100
        Write-Progress -Activity "Move-File" -Status "Working" -CurrentOperation $File.FullName -PercentComplete $p

        $fullName = $File.FullName
        Write-Verbose -Message "Move-File process >>> [$fullName] "  

        #Exists content in destination
        $fileHash = Get-FileHash -Path $File
        $fileFound = Find-HashTable -FileHash $fileHash

        if ($fileFound) {
            Write-Warning -Message "Content [$fullName] found on destination =>  [$fileFound]"

            Write-Verbose -Message "Decide what to do if Skip or move to a different place."            
        } else {
            #MoveAndUpdate
            $MovedFile = Move-FileToDestination -File $File -Destination $Destination
            Update-HashTable -File $MovedFile
        }

        Write-Verbose -Message "Move-File process <<< [$fullName]"  
    }   
    
    end {
        Write-Verbose -Message "Move-File end <<<"
        Write-Verbose -Message "Proccessed [$count] files"
    }
}

function Move-File2 {
    <#
    .SYNOPSIS
        Move files to destination checking if content already there.
    .DESCRIPTION
        Long description
    .EXAMPLE
        Example of how to use this cmdlet
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [string[]] $Path,
        [Parameter()] [string] $Destination

    )
    
    begin {
        $count = 0 
        $countRenamed = 0

        $Destination ??= "."

        if (!($Destination | Test-Path)) {
            "Destination not found [{0}]" -f $Destination | Write-Error
            $Destination = $null
            return
        }
    }
    
    process {

        if (!$Destination) {
            return $null
        }

        if (!($Path | Test-Path)) {
            "Source path not found [{0}]" -f $Path | Write-Error
            return
        }

        $files = Get-ChildItem -Path $Path 
        foreach ($file in $files) {
        
            $count++

            $p = $count%100
            Write-Progress -Activity "Move-File" -Status "Working" -CurrentOperation $file.FullName -PercentComplete $p
    
            $fullName = $file.FullName
    
            #Exists content in destination
            $fileHash = Get-FileHash -Path $file
            $fileFound = Find-HashTable -FileHash $fileHash
    
            if ($fileFound) {
                "Content [{0}] found on destination =>  [$fileFound]" -f $file.FullName,$fileFound | Write-Warning 
    
                Write-Verbose -Message "Decide what to do if Skip or move to a different place."            
            } else {
                #MoveAndUpdate
                $MovedFile = Move-FileToDestination -File $file -Destination $Destination
                Update-HashTable -File $MovedFile
            }
    

            #Move
            
            $movemessage = "[{0}] -> [{1}]" -f $file.FullName, $targetpath

            if ($PSCmdlet.ShouldProcess($movemessage,"MOVE")) {
                Move-Item -Path $file -Destination $targetpath  
            } 

            # [PSCustomObject]@{
            #     Source = $file.FullName
            #     Destination = $targetpath.FullName
            # }
        }
    }
    
    end {
        [PSCustomObject]@{
            Moved = $count
            Renamed = $countRenamed          
        }
    }
}

function Get-FileCopyName{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0,ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")][string[]] $Path
    )

    "somemessage" | Trace-Message
    if (!($Path | Test-Path)) {
        return $Path
    }

    $item = $Path | Get-Item
    
    $directory = $item | Split-Path -Parent
    $name = $item | Split-Path -Leaf
    $nameBase = $item | Split-Path -LeafBase
    $ext = $item | Split-Path -Extension

    $count = 0

    do {
        $count++
        $name =  $nameBase + "($count)" + $ext
        $targetFullname = Join-Path -Path $directory -ChildPath $name
        
    } while ($targetFullname | Test-Path)

    return $targetFullname
}

function Move-FileToDestination {
    <#
    .SYNOPSIS
        Move files to destination. If exist will rename to allow the move.
    .DESCRIPTION
        Long description
    .EXAMPLE
        Example of how to use this cmdlet
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [string[]] $Path,
        [Parameter()] [string] $Destination
    )
    
    begin {
        $count = 0 
        $countRenamed = 0

        $Destination ??= "."

        if (!($Destination | Test-Path)) {
            "Destination not found [{0}]" -f $Destination | Write-Error
            $Destination = $null
            return
        }
    }
    
    process {

        if (!$Destination) {
            return $null
        }

        if (!($Path | Test-Path)) {
            "Source path not found [{0}]" -f $Path | Write-Error
            return
        }

        $files = Get-ChildItem -Path $Path 
        foreach ($file in $files) {
        
            $count++

            $targetpath = $Destination | Join-Path -ChildPath $File.Name

            if ($Targetpath | Test-Path) {
                $targetpath = Get-FileCopyName -Path $targetpath
                $countRenamed++
            }      
           
            #Move
            
            $movemessage = "[{0}] -> [{1}]" -f $file.FullName, $targetpath

            if ($PSCmdlet.ShouldProcess($movemessage,"MOVE")) {
                Move-Item -Path $File -Destination $targetpath  
            } 

            # [PSCustomObject]@{
            #     Source = $file.FullName
            #     Destination = $targetpath.FullName
            # }
        }
    }
    
    end {
        [PSCustomObject]@{
            Moved = $count
            Renamed = $countRenamed          
        }
    }
}

function Compare-File{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $With
    )

    if (-not ($Path | Test-Path)) {
        # $PSCmdlet.WriteError("Error message")
        Write-Error -Message ("Path file not found [{0}]" -f $Path) -RecommendedAction "Please check that the file exists"
        return $false
    }

    if (-not ($With | Test-Path)) {
        Write-Error -Message ("With file not found [{0}]" -f $With) -RecommendedAction "Please check that the file exists"
        return $false
    }

    $pathFile = $Path | Resolve-Path
    $withFile = $With | Resolve-Path

    if ($pathFile -eq $withFile) {
        "Compareing the same file [{0}]" -f $sourceFile | Write-warning
        return $true
    }

    $p1 = Get-FileHash -Path $Path
    $p2 = Get-FileHash -Path $With

    return $p1.Hash -eq $p2.Hash
}

function Test-FileContent{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [string[]] $Path,
        [Parameter()] [string] $Destination
    )

    begin {

        if ([string]::IsNullOrEmpty($Destination)) {
            $Destination = (Get-location).Path
        }

        if (!($Destination | Test-Path)) {
            "Destination not found [{0}]" -f $Destination | Write-Error
            $Destination = $null
            return
        }
    }

    process{

        if (!($Path | Test-Path)) {
            "Source path not found [{0}]" -f $Path | Write-Error
            return
        }

        $files = Get-ChildItem -Path $Path
        foreach ($file in $files) {
            
            $destinationFilePath = $Destination | Join-Path -ChildPath ($file | Split-Path -Leaf) | Convert-Path
            
            $ret = Compare-File -Path $file -With $destinationFilePath

            return $ret
        }
    }
}

function Get-FilesDetails{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)][Alias("PSPath")][string[]]$Path
    )

    begin{
        $objShell = New-Object -ComObject Shell.application
    }

    process{
        if([string]::IsNullOrWhiteSpace($Path)){$Path = Get-Location}
        
        $items = @($Path | Get-ChildItem -File )
        
        foreach ($item in $items) {

            $details = @{}

            $folder = $item | Split-Path -Parent
            $strFileName = $item.Name

            $objFolder = $objShell.NameSpace($folder)
            $ObjFile = $objFolder.ParseName($strFileName )

            # while ($i -le 266 -and ($objFolder.getDetailsOf($file.BaseName,$i++) -ne $DetailName)) {}

            for ($a = 0; $a -le 266; $a++) 
            { 
                $detailValue = $objFolder.getDetailsOf($ObjFile, $a)
                
                if($detailValue){
                    $detailName = $objFolder.getDetailsOf($objFolder.items, $a)
                    "{0} - {1} - {2}" -f $a, $detailName, $detailValue | Write-Verbose

                    $details += @{ $detailName  = $detailValue }
                }
                
            } #end for

            # $ret += [PSCustomObject] $details
            return [PSCustomObject] $details
        }

        end {

        }
    }    
}

function Get-FilesDetail{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)][Alias("PSPath")][string[]]$Path,
        [Parameter()][string]$DetailName
    )

    begin{
        $objShell = New-Object -ComObject Shell.application
    }

    process{
        if([string]::IsNullOrWhiteSpace($Path)){$Path = Get-Location}
        
        $items = @($Path | Get-ChildItem -File )
        
        foreach ($item in $items) {

            $details = @{}

            $folder = $item | Split-Path -Parent
            $strFileName = $item.Name

            $objFolder = $objShell.NameSpace($folder)
            $ObjFile = $objFolder.ParseName($strFileName )

            $details = GetDetailsName($objFolder)
            $id = $details.$DetailName
            
            if ($id){

                $value = $objFolder.getDetailsOf($ObjFile, $details.$DetailName)

                if($value){
                    return $value
                }
            }

            return $null
        }
    }
       
}

function GetDetailsName($objFolder){
    $ret = @{}
    
    for ($i = 0; $i -lt 266; $i++) {
        $d = $objFolder.GetDetailsOf($null,$i)
        # check Detail not empty and not yet added to list
        if ($d -and !($ret.$d)) {
            $ret.Add($d,$i)
        }
    }

    return $ret
}
