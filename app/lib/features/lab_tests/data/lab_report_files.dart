import 'package:file_picker/file_picker.dart';

/// Folder (under the app documents folder) that keeps lab report photos and files. Kept
/// apart from scouting and claim photos; cleared on an account switch.
const labReportFolder = 'lab_reports';

/// File types a lab report or Soil Health Card usually comes as.
const labReportExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

/// Lets the grower choose a report file already on the phone (a PDF from WhatsApp or the
/// Soil Health Card portal); its temporary path, or null when cancelled. An interface so
/// screens and tests never touch the platform plugin.
// ignore: one_member_abstracts
abstract interface class ReportFilePicker {
  Future<String?> pick();
}

/// `file_picker` adapter; the flow is covered by tests with a fake.
class DeviceReportFilePicker implements ReportFilePicker {
  const DeviceReportFilePicker();

  @override
  Future<String?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: labReportExtensions,
    );
    return file?.path;
  }
}
