import 'accounts_csv.dart';

/// Splits the ledger over report pages. The first page also carries the title and summary, so
/// it holds fewer rows. An empty ledger still yields one (empty) page for the summary.
List<List<LedgerLine>> paginateLedger(
  List<LedgerLine> lines, {
  required int firstPageRows,
  required int otherPageRows,
}) {
  final pages = <List<LedgerLine>>[lines.take(firstPageRows).toList()];
  for (var i = firstPageRows; i < lines.length; i += otherPageRows) {
    pages.add(lines.skip(i).take(otherPageRows).toList());
  }
  return pages;
}
