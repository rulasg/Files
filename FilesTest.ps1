[CmdletBinding()]
param ()

$ModuleName = "Files"

Import-Module -Name TestingHelper -Force

# Test-Module -Name $ModuleName -TestName FilesTest_GetIncrementaName_onPath
Test-Module -Name $ModuleName 
