import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../domain/market_lot.dart';

/// The lot's photos as a row of square thumbnails, with a remove mark on drafts.
class LotPhotoStrip extends StatelessWidget {
  const LotPhotoStrip({
    required this.photos,
    this.onRemove,
    this.size = 88,
    super.key,
  });

  final List<LotPhoto> photos;
  final ValueChanged<LotPhoto>? onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.bm;
    return Wrap(
      key: const Key('lot-photo-strip'),
      spacing: BmSpace.xs,
      runSpacing: BmSpace.xs,
      children: [
        for (final p in photos)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(BmRadius.chip),
                child: p.photoPath == null
                    ? Container(
                        width: size,
                        height: size,
                        color: c.card,
                        child: Icon(
                          p.uploaded
                              ? Icons.cloud_done_outlined
                              : Icons.photo_outlined,
                          color: c.inkMuted,
                        ),
                      )
                    : Image.file(
                        File(p.photoPath!),
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        cacheWidth: (size * 3).round(),
                        errorBuilder: (_, _, _) => SizedBox.square(
                          dimension: size,
                          child: Icon(Icons.photo_outlined, color: c.inkMuted),
                        ),
                      ),
              ),
              if (onRemove case final remove?)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton.filledTonal(
                    key: Key('lot-photo-remove-${p.id}'),
                    tooltip: t.mlRemovePhoto,
                    iconSize: 18,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => remove(p),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// "3 to 8 photos" in the locale's digits.
String photosHint(AppLocalizations t, String lang) => t.mlPhotosHint(
  formatInt(lotMinPhotos, lang),
  formatInt(lotMaxPhotos, lang),
);
