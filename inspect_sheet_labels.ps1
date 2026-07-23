Add-Type -AssemblyName System.IO.Compression.FileSystem
$path = Join-Path $PSScriptRoot 'Fake_Databook_Full.xlsx'
$zip = [System.IO.Compression.ZipFile]::OpenRead($path)
$wbEntry = $zip.Entries | Where-Object { $_.FullName -eq 'xl/workbook.xml' }
if (-not $wbEntry) { Write-Error 'workbook.xml missing'; exit 1 }
$wbStream = $wbEntry.Open()
$wbReader = [System.IO.StreamReader]::new($wbStream)
$wbXml = [xml]$wbReader.ReadToEnd()
$wbReader.Close()
$ns = [System.Xml.XmlNamespaceManager]::new($wbXml.NameTable)
$ns.AddNamespace('d','http://schemas.openxmlformats.org/spreadsheetml/2006/main')
$sheetMap = @{}
foreach ($sheet in $wbXml.SelectNodes('//d:sheet',$ns)) {
  $sheetMap[$sheet.GetAttribute('name')] = $sheet.GetAttribute('r:id')
}
$relsEntry = $zip.Entries | Where-Object { $_.FullName -eq 'xl/_rels/workbook.xml.rels' }
$relsStream = $relsEntry.Open()
$relsReader = [System.IO.StreamReader]::new($relsStream)
$relsXml = [xml]$relsReader.ReadToEnd()
$relsReader.Close()
$nsr = [System.Xml.XmlNamespaceManager]::new($relsXml.NameTable)
$nsr.AddNamespace('r','http://schemas.openxmlformats.org/package/2006/relationships')
$relMap = @{}
foreach ($rel in $relsXml.SelectNodes('//r:Relationship',$nsr)) {
  $relMap[$rel.GetAttribute('Id')] = $rel.GetAttribute('Target')
}
$sstEntry = $zip.Entries | Where-Object { $_.FullName -eq 'xl/sharedStrings.xml' }
$sstXml = if ($sstEntry) {
  $sstStream = $sstEntry.Open()
  $sstReader = [System.IO.StreamReader]::new($sstStream)
  $xmlContent = $sstReader.ReadToEnd()
  $sstReader.Close()
  [xml]$xmlContent
} else {
  $null
}
$nsS = if ($sstXml) { $ns2 = [System.Xml.XmlNamespaceManager]::new($sstXml.NameTable); $ns2.AddNamespace('x','http://schemas.openxmlformats.org/spreadsheetml/2006/main'); $ns2 } else {$null}

function Get-SharedString($idx) {
  if (-not $sstXml) { return '' }
  $si = $sstXml.SelectSingleNode("//x:si[$($idx+1)]", $nsS)
  if (-not $si) { return '' }
  return ($si.SelectNodes('.//x:t',$nsS) | ForEach-Object { $_.'#text' }) -join ''
}

function ReadSheet($name, $rowLimit) {
  if (-not $sheetMap.ContainsKey($name)) { Write-Output "Sheet missing: $name"; return }
  $rid = $sheetMap[$name]
  $target = 'xl/' + $relMap[$rid]
  $sheetEntry = $zip.Entries | Where-Object { $_.FullName -eq $target }
  if (-not $sheetEntry) { Write-Output "Sheet entry missing: $target"; return }
  $sheetStream = $sheetEntry.Open()
  $sheetReader = [System.IO.StreamReader]::new($sheetStream)
  $sheetXml = [xml]$sheetReader.ReadToEnd()
  $sheetReader.Close()
  $ns3 = [System.Xml.XmlNamespaceManager]::new($sheetXml.NameTable)
  $ns3.AddNamespace('x','http://schemas.openxmlformats.org/spreadsheetml/2006/main')
  Write-Output "=== $name ==="
  $count = 0
  foreach ($row in $sheetXml.SelectNodes('//x:sheetData/x:row',$ns3)) {
    $r = [int]$row.GetAttribute('r')
    $cells = @{}
    foreach ($c in $row.SelectNodes('x:c',$ns3)) {
      $ref = $c.GetAttribute('r')
      $t = $c.GetAttribute('t')
      $v = $c.SelectSingleNode('x:v',$ns3)
      if (-not $v) { $cells[$ref] = '' ; continue }
      if ($t -eq 's') { $cells[$ref] = Get-SharedString([int]$v.'#text') } else { $cells[$ref] = $v.'#text' }
    }
    $formatted = ($cells.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.ToString() }) -join ' | '
    Write-Output "$($r): $formatted"
    $count++
    if ($count -ge $rowLimit) { break }
  }
  Write-Output ''
}

$sheetNames = @('Monthly IS','EBITDA Analysis','Payroll Analysis','Common Size Analysis')
foreach ($name in $sheetNames) { ReadSheet $name 80 }
$zip.Dispose()