import '../accounts/data/accounts_repository.dart';
import '../accounts/domain/accounts.dart';
import '../bahar/data/bahar_repository.dart';
import '../bahar/domain/bahar_cycle.dart';
import '../field_work/data/field_work_repository.dart';
import '../field_work/domain/field_work.dart';
import '../inputs/data/inputs_repository.dart';
import '../inputs/domain/field_records.dart';
import '../plots/data/plot_repository.dart';
import '../plots/domain/plot.dart';
import '../spray/data/spray_repository.dart';
import '../spray/domain/spray_record.dart';

/// A sample orchard for test builds so no screen is empty: one Nagpur mandarin block near Shindi
/// Khurd, Chandur Bazar (Amravati) with Mrig bahar in progress and a few records. The boundary is a
/// placeholder square, not the real block: walk the real one with "Add this corner". Fixed ids make
/// running it twice update the same rows instead of duplicating them.
class SampleOrchard {
  const SampleOrchard({
    required this.plots,
    required this.bahars,
    required this.accounts,
    required this.sprays,
    required this.inputs,
    required this.fieldWork,
  });

  final PlotRepository plots;
  final BaharRepository bahars;
  final AccountsRepository accounts;
  final SprayRepository sprays;
  final InputsRepository inputs;
  final FieldWorkRepository fieldWork;

  static const plotId = 'a0000000-0000-4000-8000-000000000001';
  static const cycleId = 'a0000000-0000-4000-8000-000000000002';
  static String _id(int n) =>
      'a0000000-0000-4000-8000-${(100 + n).toString().padLeft(12, '0')}';

  /// Placeholder square of about 4 acres near Shindi Khurd (lat, lon).
  static const _lat = 21.2300;
  static const _lon = 77.7500;
  static const _dLat = 0.00115;
  static const _dLon = 0.00123;

  Future<void> run() async {
    await plots.save(
      const Plot(
        id: plotId,
        name: 'Shindi Khurd block 1 (sample)',
        crop: 'santra',
        areaSqM: 16187,
        variety: 'Nagpur mandarin',
        plantingYear: 2014,
        treeCount: 450,
        rowSpacingM: 6,
        plantSpacingM: 6,
        centroidLat: _lat + _dLat / 2,
        centroidLon: _lon + _dLon / 2,
        boundary: {
          'type': 'Polygon',
          'coordinates': [
            [
              [_lon, _lat],
              [_lon + _dLon, _lat],
              [_lon + _dLon, _lat + _dLat],
              [_lon, _lat + _dLat],
              [_lon, _lat],
            ],
          ],
        },
      ),
    );
    await bahars.save(
      BaharCycle(
        id: cycleId,
        plotId: plotId,
        bahar: 'mrig',
        seasonYear: 2026,
        status: 'active',
        actual: {
          'stress_start': DateTime(2026, 4, 20),
          'flowering': DateTime(2026, 6, 25),
        },
      ),
    );
    await accounts.saveExpense(
      Expense(
        id: _id(1),
        plotId: plotId,
        baharCycleId: cycleId,
        spentOn: DateTime(2026, 7, 2),
        category: 'irrigation',
        amountPaise: 450000,
        note: 'Drip and pump electricity',
      ),
    );
    await accounts.saveIncome(
      Income(
        id: _id(2),
        plotId: plotId,
        baharCycleId: cycleId,
        soldOn: DateTime(2026, 3, 18),
        buyerName: 'Sample buyer',
        quantityKg: 2400,
        ratePaisePerQuintal: 2800000,
        paymentStatus: 'paid',
        paidPaise: 6720000,
        paidOn: DateTime(2026, 3, 20),
      ),
    );
    await sprays.save(
      SprayRecord(
        id: _id(3),
        plotId: plotId,
        baharCycleId: cycleId,
        sprayedOn: DateTime(2026, 7, 10),
        productName: 'Sample product',
        dose: '2 ml per litre',
        waterLitres: 600,
        areaAcres: 4,
        costPaise: 240000,
      ),
    );
    await inputs.saveInput(
      InputRecord(
        id: _id(4),
        plotId: plotId,
        baharCycleId: cycleId,
        appliedOn: DateTime(2026, 6, 5),
        kind: 'manure',
        productName: 'Farmyard manure',
        quantity: 6,
        unit: 'trolley',
        costPaise: 900000,
      ),
    );
    await inputs.saveIrrigation(
      IrrigationRecord(
        id: _id(5),
        plotId: plotId,
        baharCycleId: cycleId,
        irrigatedOn: DateTime(2026, 7, 14),
        durationHours: 4,
      ),
    );
    await fieldWork.saveLabour(
      LabourRecord(
        id: _id(6),
        plotId: plotId,
        baharCycleId: cycleId,
        workerName: 'Sample worker',
        workedOn: DateTime(2026, 7, 11),
        wagePaise: 40000,
        task: 'spraying',
      ),
    );
    await fieldWork.saveHarvest(
      HarvestRecord(
        id: _id(7),
        plotId: plotId,
        baharCycleId: cycleId,
        harvestedOn: DateTime(2026, 3, 15),
        quantityKg: 2400,
      ),
    );
  }
}
