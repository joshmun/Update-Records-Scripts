if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
     Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
Import-Module -Name 'C:\Scripts\Module Update-RPField.psm1' -Force

$workingFolder = 'C:\Scripts\Module Update-RPField\Document'

$params = @{
    StorageUrl = 'http://ruby-mun:5555/Content/RPContent_20170906232624/'
    ListName = 'Files_20170906233114'
    SPListItemId = 14
    NewFieldValue = 'HELLO'
    NewFieldType ='Text'
    NewFieldName = 'Record Classification'
    WorkingFolder = $workingFolder
    AddMissingXMLNode = $false
}


Update-RPField @params