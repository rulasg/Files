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

function FilesTest_Sample(){
    Assert-IsTrue -Condition $true
}

Export-ModuleMember -Function FilesTest_*
