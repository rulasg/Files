[CmdletBinding()]
param ()

$ModuleName = "Files"

Import-Module -Name TestingHelper -Force

Test-Module -Name $ModuleName 
