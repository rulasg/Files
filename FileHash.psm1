##############################################################

class FileHashTable{

    [string ] $hashCacheDefaultFileName = '.hashcache'
    [System.Collections.Hashtable] $hashTable

    HashTable(){
        this.$Reset
    }

    [void] Reset(){ 
        $this.hashTable = @{}
        $this.DeleteCache()
    }

    [void] DeleteCache([string] $FileName=$null){

        if (-Not $FileName) {
            $FileName = $this.hashCacheDefaultFileName
        }

        if (Test-Path -Path $FileName) {
            Remove-Item -Path $FileName
        }
    }

    [void]SaveToCache([string]$FileName=$null){

        if (-Not $FileName) {
            $FileName = $this.hashCacheDefaultFileName
        }
        $global:hashTable | ConvertTo-Json  | Out-File -FilePath $FileName -Force
    }

    [void]RestoreFromCache([string]$FileName=$null){
        if (-Not $FileName) {
            $FileName = $this.hashCacheDefaultFileName
        }
        if  (Test-Path -Path $FileName) {
            
            $this.hashTable = Get-Content $FileName | Out-String | ConvertFrom-Json
        }
    }

    [bool] Contains([string]$FullName){
        return $this.hashTable.Contains($FullName)
    }

    [bool] Add([string] $FullName){

        if ($this.Contains($FullName)) {
            return false
        }

        $this.AddOrUpdate($FullName)

        return $true
    }

    [void] AddOrUpdate ([string]$FullName){

        $fileHash = Get-FileHash -Path $FullName

        $this.hashTable.Add($fileHash.Path,$fileHash.Hash)
    }

    [void] Remove ([string]$FullName){
        $this.hashTable.Remove($FullName)
    }
}

function Find-HashTableDuplicates {
    [CmdletBinding()]
    param( 
        [parameter(ValueFromPipeline=$true)]
        [System.IO.FileInfo] $File
    )
    
    begin{
        [System.Collections.ArrayList]$duplicateList = [System.Collections.ArrayList]::new()
        $count = 0
    }
    
    process {
        $count++
        $p = $count%100
        Write-Progress -Activity "Finding Duplicates" -Status "Working" -CurrentOperation $File.FullName -PercentComplete $p
        $ret = Update-HashTable -File $File
        if (-Not $ret ){
            $duplicateList += $File
        }
    }
    
    end {
        Write-Host "Processed [$count]"
        $CountDuplicates = $duplicateList.Count
        Write-Host "Duplicates [$CountDuplicates]"

        $duplicateList
    }
}

function Update-FileHashTable {
    [CmdletBinding()]
    param( 
        [parameter(ValueFromPipeline=$true)]
        [System.IO.FileInfo] $File,
        [switch] $UseCache,
        [switch] $Reset
    )

    begin{

        if ($ResetCache) {
            $global:FileHashTable.Reset()
        }

        if ($UseCache){
            $global:FileHashTable.RestoreFromCache()
        }
    }

    process {            
        Write-Verbose -Message  "Update-FileHashTable [$fullName]"

        $foundFile = $global:FileHashTable.Add($File.FullName)

        if ($foundFile) {
            $fileName = $File.FullName
            Write-Information -Message "$FileName content already present in HashTable [$foundFile] "

        } else {
            Write-Verbose -Message "HasTable += $path"
        }
    }

    end {
        if ($UseCache -or $ResetCache) {
            $global:FileHashTable.SaveToCache()
        }
    }
}

function Find-HashTable{
    [CmdletBinding()]
    param(
          $Hash,
          $Path
    )

    if (-Not $HASH) {
        
    }
    $found = $global:hashTable[$FileHash.Hash]


    if ($found) {
        Write-verbose -Message "Found file on HashTable with same hash => [$ret]"
        return $found
    } else {
        Write-verbose -Message "File not present in HashTable"
        return $null
    }
}

$global:FileHashTable = [FileHashTable]::new()