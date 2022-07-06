[CmdletBinding()]
param ()

$ModuleName = "Files"

Import-Module -Name TestingHelper -Force

Test-Module -Name $ModuleName -TestName FilesTest_GetFilesDetails_SimpleManyFiles
# Test-Module -Name $ModuleName 
