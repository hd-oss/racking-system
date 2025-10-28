import 'dart:io';

void main() async {
  // Create temporary directory
  final tempDir = Directory('_excel_temp');
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
  tempDir.createSync();

  debugLog('Creating Excel structure...');

  // Create directory structure
  Directory('_excel_temp/_rels').createSync();
  Directory('_excel_temp/xl').createSync();
  Directory('_excel_temp/xl/_rels').createSync();
  Directory('_excel_temp/xl/worksheets').createSync();
  Directory('_excel_temp/xl/theme').createSync();

  // Create [Content_Types].xml
  const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
<Override PartName="/xl/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>''';
  await File('_excel_temp/[Content_Types].xml').writeAsString(contentTypesXml);

  // Create _rels/.rels
  const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';
  await File('_excel_temp/_rels/.rels').writeAsString(relsXml);

  // Create xl/_rels/workbook.xml.rels
  const workbookRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
</Relationships>''';
  await File('_excel_temp/xl/_rels/workbook.xml.rels')
      .writeAsString(workbookRels);

  // Create xl/workbook.xml
  const workbookXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x15" xmlns:x15="http://schemas.microsoft.com/office/spreadsheetml/2010/11/main">
<fileVersion appName="xl" lastEdited="4" lowestEdited="4" rupBuild="16816"/>
<workbookPr defaultTheme="1"/>
<sheets>
<sheet name="Racking" sheetId="1" r:id="rId1"/>
</sheets>
</workbook>''';
  await File('_excel_temp/xl/workbook.xml').writeAsString(workbookXml);

  // Create xl/sharedStrings.xml
  const sharedStringsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="10" uniqueCount="10">
<si><t>Rak</t></si>
<si><t>Level</t></si>
<si><t>Occupied</t></si>
<si><t>IN</t></si>
<si><t>OUT</t></si>
</sst>''';
  await File('_excel_temp/xl/sharedStrings.xml')
      .writeAsString(sharedStringsXml);

  // Create xl/styles.xml
  const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="1"><font><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/><scheme val="minor"/></font></fonts>
<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>
</styleSheet>''';
  await File('_excel_temp/xl/styles.xml').writeAsString(stylesXml);

  // Create xl/theme/theme1.xml
  const themeXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
<a:themeElements>
<a:clrScheme name="Office">
<a:dk1><a:srgbClr val="000000"/></a:dk1>
<a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
<a:dk2><a:srgbClr val="44546A"/></a:dk2>
<a:lt2><a:srgbClr val="D9D9D9"/></a:lt2>
<a:accent1><a:srgbClr val="5B9BD5"/></a:accent1>
<a:accent2><a:srgbClr val="ED7D31"/></a:accent2>
<a:accent3><a:srgbClr val="A5A5A5"/></a:accent3>
<a:accent4><a:srgbClr val="FFC000"/></a:accent4>
<a:accent5><a:srgbClr val="5B9BD5"/></a:accent5>
<a:accent6><a:srgbClr val="70AD47"/></a:accent6>
<a:hyperlink><a:srgbClr val="0563C1"/></a:hyperlink>
<a:folHyperlink><a:srgbClr val="954F72"/></a:folHyperlink>
</a:clrScheme>
<a:fontScheme name="Office">
<a:majorFont><a:latin typeface="Calibri Light"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>
<a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>
</a:fontScheme>
</a:themeElements>
</a:theme>''';
  await File('_excel_temp/xl/theme/theme1.xml').writeAsString(themeXml);

  // Create xl/worksheets/sheet1.xml with Racking format data
  // Format: Rak | Level | Occupied (IN/OUT)
  final sheetXmlBuffer = StringBuffer(
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">
<sheetPr filterOn="false"><outlinePr summaryBelow="true" summaryRight="true"/></sheetPr>
<sheetData>
<row r="1" spans="1:3" ht="15" customHeight="true"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="C1" t="s"><v>2</v></c></row>
''');

  // Sample data: Rak, Level, Occupied (IN=true, OUT=false)
  final sampleData = [
    [1, 1, 'IN'],   // Rak 1, Level 1, Occupied
    [1, 2, 'OUT'],  // Rak 1, Level 2, Empty
    [2, 1, 'IN'],   // Rak 2, Level 1, Occupied
    [2, 2, 'OUT'],  // Rak 2, Level 2, Empty
    [5, 1, 'IN'],   // Rak 5, Level 1, Occupied
    [5, 2, 'OUT'],  // Rak 5, Level 2, Empty
    [8, 1, 'IN'],   // Rak 8, Level 1, Occupied
    [8, 2, 'OUT'],  // Rak 8, Level 2, Empty
  ];

  // Add data rows
  for (int i = 0; i < sampleData.length; i++) {
    final rowNum = i + 2;
    final data = sampleData[i];
    final occupied = data[2] == 'IN' ? 3 : 4; // String index in sharedStrings

    sheetXmlBuffer.write('<row r="$rowNum" spans="1:3">');
    sheetXmlBuffer.write('<c r="A$rowNum" t="n"><v>${data[0]}</v></c>');
    sheetXmlBuffer.write('<c r="B$rowNum" t="n"><v>${data[1]}</v></c>');
    sheetXmlBuffer.write('<c r="C$rowNum" t="s"><v>$occupied</v></c>');
    sheetXmlBuffer.write('</row>');
  }

  sheetXmlBuffer.write('''</sheetData>
<pageMargins left="0.75" top="1" right="0.75" bottom="1" header="0.5" footer="0.5"/>
</worksheet>''');

  await File('_excel_temp/xl/worksheets/sheet1.xml')
      .writeAsString(sheetXmlBuffer.toString());

  debugLog('Creating zip file...');

  // Create zip file using command line
  final result = await Process.run(
    'zip',
    [
      '-r',
      '-q',
      '../sample_racking_import.xlsx',
      '[Content_Types].xml',
      '_rels',
      'xl'
    ],
    workingDirectory: '_excel_temp',
  );

  if (result.exitCode == 0) {
    final file = File('sample_racking_import.xlsx');
    if (file.existsSync()) {
      final size = file.lengthSync();
      debugLog('✅ File berhasil dibuat: sample_racking_import.xlsx');
      debugLog('📊 Format: Rak | Level | Occupied (IN/OUT)');
      debugLog('📦 Ukuran file: ${(size / 1024).toStringAsFixed(1)} KB');
      debugLog('✨ File Excel siap untuk di-import!');
      debugLog('');
      debugLog('Sample data:');
      for (int i = 0; i < sampleData.length; i++) {
        final data = sampleData[i];
        debugLog('  Row ${i + 2}: Rak=${data[0]} | Level=${data[1]} | Occupied=${data[2]}');
      }
    }
  } else {
    debugLog('❌ Error saat membuat zip file');
    debugLog('Error: ${result.stderr}');
  }

  // Cleanup
  debugLog('Cleaning up temporary files...');
  await tempDir.delete(recursive: true);
}

void debugLog(String message) {
  final timestamp = DateTime.now().toString().split('.')[0];
  stdout.writeln('[$timestamp] $message');
}
