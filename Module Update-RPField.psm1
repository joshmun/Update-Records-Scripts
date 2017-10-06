$ErrorActionPreference = 'Stop'
if( (Get-PSSnapin Microsoft.SharePoint.PowerShell1 -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue
}


function Update-RPField
{
    Param(
        [Parameter(Mandatory=$true)][string]$StorageUrl,
        [Parameter(Mandatory=$true)][string]$ListName,
        [Parameter(Mandatory=$true)][int]$SPListItemId,
        [Parameter(Mandatory=$true)][string]$NewFieldName,
        [Parameter(Mandatory=$true)][string]$NewFieldValue,
        [Parameter(Mandatory=$true)][string]$NewFieldType,
        [Parameter(Mandatory=$true)][string]$WorkingFolder,
        [Parameter(Mandatory=$false)][switch]$AddMissingXMLNode
    )

    Write-Host 'Ensure working directories'
    Write-Host " > $WorkingFolder"; New-Item -Path $WorkingFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Write-Host " > $(Join-Path $WorkingFolder 'orig')"; New-Item -Path (Join-Path $WorkingFolder 'orig') -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    Write-Host " > $(Join-Path $WorkingFolder 'update')"; New-Item -Path (Join-Path $WorkingFolder 'update') -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    Write-Host "Getting Web $StorageUrl"
    $site = Get-SPWeb $StorageUrl
    if($site -eq $null) { throw 'Site not found' }

    Write-Host "Getting List $ListName"
    $list = $site.Lists[$ListName] 
    if($list -eq $null) { throw 'List not found' }

    Write-Host "Getting Item by ID $SPListItemId"
    $item = $list.GetItemById($SPListItemId)
    if($item -eq $null) { throw 'Item not found by ID' }
    else
    {
        #Throw if the property isn't on the SPItem property as well
        if($item[$NewFieldName] -eq $null){ throw $NewFieldName + ' property not found by in item' }
    }

    $file = $item.File
    $orig = [IO.Path]::Combine($WorkingFolder, 'orig', $file.Name)
    if(Test-Path $orig) { Remove-Item  $orig -Force }

    $fileBinary = $file.OpenBinary()
    $stream = New-Object System.IO.FileStream($orig), Create
    $writer = New-Object System.IO.BinaryWriter($stream)
    $writer.Write($fileBinary)
    $writer.Close()
    Write-Host "Item XML Retrieved"

    [xml]$xml = Get-Content $orig 
    $nd = $xml.Metadata.ActiveSiteProperties.Property | ?{ $_.name -eq $NewFieldName }
    if($nd -ne $null) 
    {
        Write-Host "Updating " $NewFieldName " XML Node"
        $nd.value = $NewFieldValue
    }
    else
    {
        if($AddMissingXMLNode) 
        {
            Write-Host "Adding new Record Number XML Node"
            $nd = $xml.Metadata.ActiveSiteProperties.Property[0].Clone()
            $nd.name = $NewFieldName
            $nd.type = $NewFieldType
            $nd.value = $NewFieldValue
            $xml.Metadata.ActiveSiteProperties.AppendChild($nd) | Out-Null
        }
        else
        { 
            throw 'File does not contain ' + $NewFieldName + ' field' 
        }
    }

    Write-Host "Saving new XML file"
    $update = [IO.Path]::Combine($WorkingFolder, 'update', $file.Name)
    if(Test-Path $update) { Remove-Item  $update -Force }
    $xml.Save($update)

    Write-Host "Uploading new XML file"
    $updateFile = Get-ChildItem $update
    $updateFileUrl = ([xml]$item.Xml).DocumentElement.ows_EncodedAbsUrl
    $updateFile = $list.RootFolder.Files.Add($updateFileUrl, $updateFile.OpenRead(), $true)
    $updateItem = $updateFile.Item

    Write-Host "Updating SharePoint Item " $NewFieldName " with value: " $NewFieldValue
    $updateItem[$newFieldName]=$newFieldValue
    $updateItem.SystemUpdate($false)
}

