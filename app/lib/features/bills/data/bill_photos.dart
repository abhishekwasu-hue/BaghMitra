// The bill photo on a spray record or an expense (OPEN_QUESTIONS Q136). Kept the way
// scouting photos are: the file in the app's own folder on this phone (`bill_photos/`), the
// path never synced; once the optional photo backup has uploaded it, its object key
// `<owner_id>/bill-<record_id>.jpg` is synced with the record.

/// Which record a bill photo belongs to; [wire] is the sync entity and the API path part.
enum BillKind {
  spray('spray_record'),
  expense('expense');

  const BillKind(this.wire);
  final String wire;
}

/// Folder in the app's documents directory for kept bill photos.
const billPhotoFolder = 'bill_photos';

/// One record's bill photo: the file on this phone and the backed-up key.
typedef BillPhotoRef = ({String? path, String? key});

/// What the photo backup and the thumbnails need from a repository with bill photos.
abstract interface class BillPhotoRecords {
  /// Records with a bill photo on this phone that is not backed up yet, oldest first.
  Future<List<({String id, String path})>> billPhotosToBackUp();

  /// The photo was uploaded: keep its key and send it to the server like any other edit.
  Future<void> markBillBackedUp(String id, String photoKey);

  /// A backed-up photo downloaded to this phone: remember the file (local only).
  Future<void> keepDownloadedBill(String id, String path);

  /// The record's bill photo, or null when the record is gone.
  Future<BillPhotoRef?> billPhotoOf(String id);
}
