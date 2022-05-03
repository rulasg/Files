<# 
.Synopsis 
FilesTest

.Description
Testing module for Files

.Notes 
NAME  : FilesTest.psm1*
AUTHOR: rulasg   

CREATED: 03/05/2022
#>

Write-Host "Loading FilesTest ..." -ForegroundColor DarkCyan

function FilesTest_CompareFile_NotExists{

    $result = Compare-File -Path "SomeFile.txt" -With "Otherfile.txt" -ErrorVariable 'testErrors' -ErrorAction SilentlyContinue
    
    Assert-IsFalse -Condition $result
    Assert-Count -Expected 1 -Presented $testErrors
    Assert-AreEqual -Expected "Path file not found [SomeFile.txt]" -Presented $testErrors[0].ErrorDetails.Message
    
    # Create Path
    New-TestingFile -Name "SomeFile.txt"
    
    $result = Compare-File -Path "SomeFile.txt" -With "Otherfile.txt" -ErrorVariable 'testErrors' -ErrorAction SilentlyContinue
    
    Assert-IsFalse -Condition $result
    Assert-Count -Expected 1 -Presented $testErrors
    Assert-AreEqual -Expected "With file not found [Otherfile.txt]" -Presented $testErrors[0].ErrorDetails.Message
    
}

function FilesTest_CompareFile_Simple{
    
    $f1 = New-TestingFile -Name "f1.txt" -Content "123456789" -PassThru
    $f2 = New-TestingFile -Name "f2.txt" -Content "12345678" -PassThru
    $f3 = New-TestingFile -Name "f3.txt" -Content "123456789" -PassThru
    
    $result = Compare-File -Path $f1 -With $f2
    
    Assert-IsFalse -Condition $result

    $result = Compare-File -Path $f1 -With $f3

    Assert-IsTrue -Condition $result
}


function FilesTest_GetIncrementaName_Root{
    
    $root = Get-Location | Convert-Path

    $fileName  = "somename.txt"
    $filename1 = "somename(1).txt"
    $filename2 = "somename(2).txt"
    $filename3 = "somename(3).txt"
    $filename4 = "somename(4).txt"

    #No file exists
    $result = Get-FileCopyName -Path $fileName
    
    Assert-AreEqual -Expected $fileName -Presented $result
    
    #Create one file
    New-TestingFile -Name $fileName
    
    $result = Get-FileCopyName -Path $fileName
    
    Assert-AreEqual -Expected ($root | Join-Path -ChildPath $filename1) -Presented $result
    
    # Create a few more files
    New-TestingFile -Name $fileName1
    New-TestingFile -Name $fileName2
    New-TestingFile -Name $fileName3
    
    $result = Get-FileCopyName -Path $fileName
    
    Assert-AreEqual -Expected ($root | Join-Path -ChildPath $filename4) -Presented $result
}

function FilesTest_GetIncrementaName_onPath{
    
    $folder = New-TestingFolder -Path "folder" -PassThru

    $fileName  = $folder.FullName | Join-Path -ChildPath "somename.txt" 
    $filename1 = $folder.FullName | Join-Path -ChildPath "somename(1).txt"
    $filename2 = $folder.FullName | Join-Path -ChildPath "somename(2).txt"
    $filename3 = $folder.FullName | Join-Path -ChildPath "somename(3).txt"
    $filename4 = $folder.FullName | Join-Path -ChildPath "somename(4).txt"

    #No file exists
    $result = Get-FileCopyName -Path $fileName
    
    Assert-AreEqual -Expected $fileName -Presented $result
    
    #Create one file
    New-TestingFile -Path $fileName
    
    $result = Get-FileCopyName -Path $fileName
    
    Assert-AreEqual -Expected $filename1 -Presented $result
    
    # Create a few more files
    New-TestingFile -Path $fileName1
    New-TestingFile -Path $fileName2
    New-TestingFile -Path $fileName3
    
    $result = Get-FileCopyName -Path $fileName
    
    Assert-AreEqual -Expected $filename4 -Presented $result
}

function FilesTest_GetIncrementaName_onPath_Pipe{
    
    $folder = New-TestingFolder -Path "folder" -PassThru

    $fileName  = $folder.FullName | Join-Path -ChildPath "somename.txt" 
    $filename1 = $folder.FullName | Join-Path -ChildPath "somename(1).txt"
    $filename2 = $folder.FullName | Join-Path -ChildPath "somename(2).txt"
    $filename3 = $folder.FullName | Join-Path -ChildPath "somename(3).txt"
    $filename4 = $folder.FullName | Join-Path -ChildPath "somename(4).txt"

    #No file exists
    $result = Get-FileCopyName -Path $fileName
    
    Assert-AreEqual -Expected $fileName -Presented $result
    
    #Create one file
    New-TestingFile -Path $fileName
    
    $result = $fileName | Get-FileCopyName
    
    Assert-AreEqual -Expected $filename1 -Presented $result
    
    # Create a few more files
    New-TestingFile -Path $fileName1
    New-TestingFile -Path $fileName2
    New-TestingFile -Path $fileName3
    
    $result = $fileName | Get-FileCopyName
    
    Assert-AreEqual -Expected $filename4 -Presented $result
}

function FilesTest_MoveFile_Simple{
    
    $filename = "filename.txt"
    $folderName = "folder"
    
    New-TestingFolder -Path $folderName
    New-TestingFile -Name $filename

    #File and folder
    $result = Move-FileToDestination -Path "fakefile.txt" -Destination "Fakefolder" -ErrorVariable 'errorVar' -ErrorAction SilentlyContinue
    
    Assert-IsNotNull -Object $result
    Assert-AreEqual -Expected 0 -Presented $result.Moved
    Assert-AreEqual -Expected 0 -Presented $result.Renamed
    Assert-Count -Expected 1 -Presented $errorVar
    Assert-AreEqual -Expected "Destination not found [Fakefolder]" -Presented $errorVar[0]

    # File not exit
    $result = Move-FileToDestination -Path "fakefile.txt" -Destination $folderName -ErrorVariable 'errorVar' -ErrorAction SilentlyContinue

    Assert-IsNotNull -Object $result
    Assert-AreEqual -Expected 0 -Presented $result.Moved
    Assert-AreEqual -Expected 0 -Presented $result.Renamed
    Assert-Count -Expected 1 -Presented $errorVar
    Assert-AreEqual -Expected "Source path not found [fakefile.txt]" -Presented $errorVar[0]
    
    #Folder not exits
    $result = Move-FileToDestination -Path $filename -Destination "Fakefolder" -ErrorVariable 'errorVar' -ErrorAction SilentlyContinue
    
    Assert-IsNotNull -Object $result
    Assert-AreEqual -Expected 0 -Presented $result.Moved
    Assert-AreEqual -Expected 0 -Presented $result.Renamed
    Assert-Count -Expected 1 -Presented $errorVar
    Assert-AreEqual -Expected "Destination not found [Fakefolder]" -Presented $errorVar[0]

    # All exist single 
    $result = Move-FileToDestination -Path $filename -Destination $folderName -WhatIf -ErrorVariable 'errorVar' -ErrorAction SilentlyContinue

    Assert-IsNotNull -Object $result
    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqual -Expected 1 -Presented $result.Moved
    Assert-AreEqual -Expected 0 -Presented $result.Renamed
    Assert-Count -Expected 0 -Presented $errorVar
    Assert-ItemExist -Path $filename 
    Assert-ItemNotExist -Path ($folderName | Join-Path -ChildPath $filename)

    # All exist single 
    $result = Move-FileToDestination -Path $filename -Destination $folderName -ErrorVariable 'errorVar' -ErrorAction SilentlyContinue

    Assert-IsNotNull -Object $result
    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqual -Expected 1 -Presented $result.Moved
    Assert-AreEqual -Expected 0 -Presented $result.Renamed
    Assert-Count -Expected 0 -Presented $errorVar
    Assert-ItemNotExist -Path $filename 
    Assert-ItemExist -Path ($folderName | Join-Path -ChildPath $filename)
        
}


function FilesTest_MoveFile_Simple_rename{
    
    $filename = "filename.txt"
    $filename1 = "filename(1).txt"
    $folderName = "folder"
    
    New-TestingFolder -Path $folderName
    New-TestingFile -Name $filename 
    New-TestingFile -Name $filename -Path $folderName

    $result = Move-FileToDestination -Path $filename -Destination $folderName -ErrorVariable 'errorVar' -ErrorAction SilentlyContinue

    Assert-IsNotNull -Object $result
    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqual -Expected 1 -Presented $result.Moved
    Assert-AreEqual -Expected 1 -Presented $result.Renamed
    Assert-Count -Expected 0 -Presented $errorVar
    Assert-ItemNotExist -Path $filename 
    Assert-ItemExist -Path ($folderName | Join-Path -ChildPath $filename)
    Assert-ItemExist -Path ($folderName | Join-Path -ChildPath $filename1)
}

function FilesTest_MoveFile_Simple_NoDestination{
    Assert-NotImplemented
}

function FilesTest_MoveFile_Path_WildChar{
    Assert-NotImplemented
}

function FilesTest_MoveFile_Path_Pipe{
    Assert-NotImplemented
}
function FilesTest_MoveFileToDestination{
    Assert-NotImplemented
}

Export-ModuleMember -Function FilesTest_*
