if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
     Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
Import-Module -Name 'C:\Scripts\ASIC\Module Update-RPField.psm1' -Force

$workingFolder = 'C:\Scripts\ASIC\Module Update-RPField\Document'

$params = @{
    StorageUrl = 'http://sr-sp13-kpico.cloudapp.net:90/Content/RPContent_20150901095325/'
    ListName = 'Files_20150901095827'
    SPListItemId = 190
    NewFieldValue = 'F0000000089|File;#F0000000089'
    NewFieldType ='Text'
    NewFieldName = 'Sibling'
    WorkingFolder = $workingFolder
    AddMissingXMLNode = $false
}

Update-RPField @params