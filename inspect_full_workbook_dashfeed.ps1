Add-Type -AssemblyName System.IO.Compression.FileSystem
$path = Join-Path $PSScriptRoot 'Fake_Databook_Full.xlsx'
$zip = [System.IO.Compression.ZipFile]::OpenRead($path)
$entry = $zip.Entries | Where-Object { $_.FullName -eq 'xl/workbook.xml' }
$reader = New-Object System.IO.StreamReader($entry.Open())
$xml = [xml]$reader.ReadToEnd()
$reader.Close()
$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace('d','http://schemas.openxmlformats.org/spreadsheetml/2006/main')
$sheetNode = $xml.SelectSingleNode("//d:sheet["][$*")
$reader.Dispose()