
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(TWCSInspectionApp());
}

class TWCSInspectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TWCS Inspection',
      home: InspectionFormPage(),
    );
  }
}

class InspectionFormPage extends StatefulWidget {
  @override
  _InspectionFormPageState createState() => _InspectionFormPageState();
}

class _InspectionFormPageState extends State<InspectionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  List<File> photos = [];

  String containerNumber = '';
  String size = '';
  String shippingLineCode = '';
  String manufacturingDate = '';
  String maxGrossWeight = '';
  String grade = 'B';
  String sound = 'Yes';
  String remark = '';
  String truckerName = '';
  String registrationNumber = '';
  String surveyorName = 'Manu M';
  String eirReferenceNo = '';

  List<String> surveyorNames = ['Manu M', 'Sreeraj S', 'Christy F', 'Anooj M'];

  TextEditingController dateController = TextEditingController();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && photos.length < 40) {
      setState(() {
        photos.add(File(pickedFile.path));
      });
    }
  }

  String generateEIRReference() {
    final now = DateTime.now();
    final datePart = "${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}";
    final hour = now.hour.toString();
    return 'tw$datePart$hour';
  }

  Future<void> generatePdfFromTemplate() async {
    final ByteData data = await rootBundle.load('assets/twcs_template.pdf');
    final List<int> bytes = data.buffer.asUint8List();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfPage page = document.pages[0];
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 10);

    eirReferenceNo = generateEIRReference();

    void drawCenteredText(String text, double x, double y, double width) {
      final size = font.measureString(text);
      final offsetX = x + (width - size.width) / 2;
      page.graphics.drawString(text, font, bounds: Rect.fromLTWH(offsetX, y, size.width, size.height));
    }

    drawCenteredText(containerNumber, 100, 120, 200);
    drawCenteredText(size, 320, 120, 100);
    drawCenteredText(shippingLineCode, 100, 140, 150);
    drawCenteredText(manufacturingDate, 320, 140, 100);
    drawCenteredText(maxGrossWeight, 100, 160, 150);
    drawCenteredText(grade, 320, 160, 100);
    drawCenteredText(sound, 100, 180, 150);
    drawCenteredText(truckerName, 100, 200, 200);
    drawCenteredText(registrationNumber, 320, 200, 100);
    drawCenteredText(remark, 100, 220, 300);
    drawCenteredText(surveyorName, 100, 240, 200);
    drawCenteredText(eirReferenceNo, 320, 240, 100);

    for (int i = 0; i < photos.length; i++) {
      final PdfPage imgPage = document.pages.add();
      final PdfBitmap img = PdfBitmap(photos[i].readAsBytesSync());
      imgPage.graphics.drawImage(img, Rect.fromLTWH(0, 0, imgPage.getClientSize().width, imgPage.getClientSize().height));
    }

    final List<int> pdfBytes = await document.save();
    document.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/twcs_inspection_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);

    setState(() {
      containerNumber = '';
      size = '';
      shippingLineCode = '';
      manufacturingDate = '';
      dateController.clear();
      maxGrossWeight = '';
      grade = 'B';
      sound = 'Yes';
      remark = '';
      truckerName = '';
      registrationNumber = '';
      surveyorName = 'Manu M';
      photos.clear();
    });

    Share.shareXFiles([XFile(file.path)], text: 'TWCS Inspection Report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TWCS Inspection')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            buildTextField('Container Number', (val) => containerNumber = val),
            buildTextField('Size', (val) => size = val),
            buildTextField('Shipping Line Code', (val) => shippingLineCode = val),
            TextFormField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Manufacturing Date (MM/YYYY)'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                val = val.replaceAll(RegExp(r'[^0-9]'), '');
                if (val.length >= 2) {
                  final mm = val.substring(0, 2);
                  final yyyy = val.length > 2 ? val.substring(2) : '';
                  dateController.value = TextEditingValue(
                    text: '$mm/$yyyy',
                    selection: TextSelection.collapsed(offset: '$mm/$yyyy'.length),
                  );
                  manufacturingDate = '$mm/$yyyy';
                } else {
                  dateController.value = TextEditingValue(
                    text: val,
                    selection: TextSelection.collapsed(offset: val.length),
                  );
                }
              },
            ),
            buildTextField('Max Gross Weight', (val) => maxGrossWeight = val),
            buildTextField('Trucker Name', (val) => truckerName = val),
            buildTextField('Registration No', (val) => registrationNumber = val),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'Grade'),
              value: grade,
              items: ['B', 'D', 'U', 'A'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => grade = val!),
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'Sound'),
              value: sound,
              items: ['Yes', 'No'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => sound = val!),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Remark'),
              maxLength: 500,
              onChanged: (val) => remark = val,
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'Surveyor Name'),
              value: surveyorName,
              items: surveyorNames.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => surveyorName = val!),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Take Photo (${photos.length}/40)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: generatePdfFromTemplate,
              child: Text('Submit & Generate PDF'),
            )
          ]),
        ),
      ),
    );
  }

  Widget buildTextField(String label, Function(String) onChanged) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      onChanged: (val) => onChanged(val.toUpperCase()),
    );
  }
}



