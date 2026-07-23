Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $PSScriptRoot 'Fake_Databook.xlsx'
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$workbookEntry = $zip.Entries | Where-Object { $_.FullName -eq 'xl/workbook.xml' }
if (-not $workbookEntry) { Write-Error 'workbook.xml not found'; exit 1 }
$reader = New-Object System.IO.StreamReader($workbookEntry.Open())
$workbookText = $reader.ReadToEnd()
$reader.Close()
Write-Output '---- workbook.xml raw ----'
$workbookText.Split([Environment]::NewLine) | Select-Object -First 20 | ForEach-Object { Write-Output $_ }
$xml = [xml]$workbookText
$nsMgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$nsMgr.AddNamespace('r','http://schemas.openxmlformats.org/officeDocument/2006/relationships')
$nsMgr.AddNamespace('d','http://schemas.openxmlformats.org/spreadsheetml/2006/main')
$sheets = $xml.SelectNodes('//d:sheets/d:sheet', $nsMgr)
Write-Output 'Sheets:'
foreach ($sheet in $sheets) {
  Write-Output "  $($sheet.GetAttribute('name')) -> rId=$($sheet.GetAttribute('r:id'))"
}
$relsEntry = $zip.Entries | Where-Object { $_.FullName -eq 'xl/_rels/workbook.xml.rels' }
$reader = New-Object System.IO.StreamReader($relsEntry.Open())
$relsText = $reader.ReadToEnd()
$reader.Close()
Write-Output '---- workbook.xml.rels raw ----'
$relsText.Split([Environment]::NewLine) | Select-Object -First 20 | ForEach-Object { Write-Output $_ }
$relsXml = [xml]$relsText
$nsRel = New-Object System.Xml.XmlNamespaceManager($relsXml.NameTable)
$nsRel.AddNamespace('r','http://schemas.openxmlformats.org/package/2006/relationships')
$sheetRef = $sheets | Where-Object { $_.GetAttribute('name') -eq 'DASH_FEED' }
if (-not $sheetRef) { Write-Error 'DASH_FEED sheet not found'; exit 1 }
$rid = $sheetRef.GetAttribute('r:id')
if (-not $rid) { Write-Error 'Missing r:id on DASH_FEED'; exit 1 }
$rel = $relsXml.SelectSingleNode("//r:Relationship[@Id='$rid']", $nsRel)
if (-not $rel) { Write-Error "Relationship for DASH_FEED r:id $rid not found"; exit 1 }
$sheetPath = 'xl/' + $rel.Target
$sheetEntry = $zip.Entries | Where-Object { $_.FullName -eq $sheetPath }
if (-not $sheetEntry) { Write-Error "Sheet entry $sheetPath not found"; exit 1 }
$reader = New-Object System.IO.StreamReader($sheetEntry.Open())
$sheetXml = [xml]$reader.ReadToEnd()
$reader.Close()

$sharedStrings = @()
$sharedEntry = $zip.Entries | Where-Object { $_.FullName -eq 'xl/sharedStrings.xml' }
if ($sharedEntry) {
  $reader = New-Object System.IO.StreamReader($sharedEntry.Open())
  $sharedXml = [xml]$reader.ReadToEnd()
  $reader.Close()
  $nsSst = New-Object System.Xml.XmlNamespaceManager($sharedXml.NameTable)
  $nsSst.AddNamespace('x', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
  $siNodes = $sharedXml.SelectNodes('//x:si', $nsSst)
  foreach ($si in $siNodes) {
    $textNode = $si.SelectSingleNode('x:t', $nsSst)
    if ($textNode) {
      $sharedStrings += $textNode.'#text'
      continue
    }
    $rNodes = $si.SelectNodes('x:r', $nsSst)
    if ($rNodes.Count -gt 0) {
      $text = ''
      foreach ($part in $rNodes) { $text += $part.SelectSingleNode('x:t', $nsSst).'#text' }
      $sharedStrings += $text
      continue
    }
    $sharedStrings += ''
  }
}

$nsSheet = New-Object System.Xml.XmlNamespaceManager($sheetXml.NameTable)
$nsSheet.AddNamespace('x', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
$rows = $sheetXml.SelectNodes('//x:sheetData/x:row', $nsSheet)
Write-Output 'DASH_FEED rows:'
foreach ($row in $rows) {
  $rowIndex = $row.GetAttribute('r')
  $values = @()
  foreach ($cell in $row.SelectNodes('x:c', $nsSheet)) {
    $cellRef = $cell.GetAttribute('r')
    $value = ''
    if ($cell.GetAttribute('t') -eq 's') {
      $idx = [int]$cell.SelectSingleNode('x:v', $nsSheet).'#text'
      $value = $sharedStrings[$idx]
    } else {
      $vNode = $cell.SelectSingleNode('x:v', $nsSheet)
      if ($vNode) { $value = $vNode.'#text' }
    }
    $values += "$cellRef=$value"
  }
  Write-Output ($rowIndex + ': ' + ($values -join ' | '))
}
Write-Output 'Shared strings:'
for ($i=0; $i -lt $sharedStrings.Count; $i++) {
  Write-Output ($i.ToString() + ': ' + $sharedStrings[$i])
}
$zip.Dispose()