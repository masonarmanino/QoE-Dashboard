Add-Type -AssemblyName System.IO.Compression.FileSystem
$path = Join-Path $PSScriptRoot 'Fake_Databook_Full.xlsx'
$zip = [System.IO.Compression.ZipFile]::OpenRead($path)
$workbook = $zip.Entries | Where-Object { $_.FullName -eq 'xl/workbook.xml' }
if (-not $workbook) { Write-Error 'workbook.xml not found'; exit 1 }
$wbText = [System.IO.StreamReader]::new($workbook.Open()).ReadToEnd()
$sheetPattern = '<sheet[^>]*name="(?<name>[^"]+)"[^>]*r:id="(?<rid>[^"]+)"'
$sheetMatches = [regex]::Matches($wbText, $sheetPattern)
$sheetMap = @{}
foreach ($m in $sheetMatches) {
  $sheetMap[$m.Groups['name'].Value] = $m.Groups['rid'].Value
}
$rels = $zip.Entries | Where-Object { $_.FullName -eq 'xl/_rels/workbook.xml.rels' }
$relsText = [System.IO.StreamReader]::new($rels.Open()).ReadToEnd()
$relPattern = '<Relationship[^>]*Id="(?<id>[^"]+)"[^>]*Target="(?<t>[^"]+)"'
$relMap = @{}
foreach ($m in [regex]::Matches($relsText, $relPattern)) {
  $relMap[$m.Groups['id'].Value] = $m.Groups['t'].Value
}
$sst = $zip.Entries | Where-Object { $_.FullName -eq 'xl/sharedStrings.xml' }
$sstText = ''
if ($sst) {
  $sstText = [System.IO.StreamReader]::new($sst.Open()).ReadToEnd()
}
Write-Output 'Sheets in workbook:'
$sheetMap.Keys | ForEach-Object { Write-Output "- $_" }
Write-Output ''
function PrintSheetRows($sheetName, $rowLimit) {
  if (-not $sheetMap.ContainsKey($sheetName)) { Write-Output "Sheet missing: $sheetName"; return }
  $rid = $sheetMap[$sheetName]
  $target = 'xl/' + $relMap[$rid]
  $entry = $zip.Entries | Where-Object { $_.FullName -eq $target }
  if (-not $entry) { Write-Output "Sheet target missing: $target"; return }
  $text = [System.IO.StreamReader]::new($entry.Open()).ReadToEnd()
  Write-Output "=== $sheetName ==="
  $rowPattern = '<row[^>]*r="(?<r>\d+)"[^>]*>(?<row>.*?)</row>'
  $rowMatches = [regex]::Matches($text, $rowPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  $count = 0
  foreach ($rm in $rowMatches) {
    $r = $rm.Groups['r'].Value
    $rowXml = $rm.Groups['row'].Value
    $cells = [regex]::Matches($rowXml, '<c[^>]*r="(?<ref>[^"]+)"(?:[^>]*t="(?<t>[^"]+)")?[^>]*>(?<cell>.*?)</c>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $values = @()
    foreach ($c in $cells) {
      $col = $c.Groups['ref'].Value
      $t = $c.Groups['t'].Value
      $cellXml = $c.Groups['cell'].Value
      $v = [regex]::Match($cellXml, '<v>(?<v>.*?)</v>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
      $value = $v.Groups['v'].Value
      if ($t -eq 's') {
        $ss = [regex]::Matches($sstText, '<si>(?<si>.*?)</si>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $int = [int]$value
        if ($int -lt $ss.Count) {
          $siText = $ss[$int].Groups['si'].Value
          $textMatch = [regex]::Matches($siText, '<t[^>]*>(?<t>.*?)</t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
          $value = ($textMatch | ForEach-Object { $_.Groups['t'].Value }) -join ''
        }
      }
      $values += "$col=$value"
    }
    $joined = $values -join ' | '
    Write-Output "$($r): $joined"
    $count++
    if ($count -ge $rowLimit) { break }
  }
  Write-Output ''
}
$names = @('Monthly IS','EBITDA Analysis','Payroll Analysis','Common Size Analysis','Mthly Rev and Margin Trends','SG&A Analysis')
foreach ($name in $names) { PrintSheetRows $name 40 }
$zip.Dispose()