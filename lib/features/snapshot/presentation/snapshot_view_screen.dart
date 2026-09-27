import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../../../domain/snapshot/snapshot_image.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';

class SnapshotViewScreen extends StatefulWidget {
  const SnapshotViewScreen({
    super.key,
    required this.image,
    required this.title,
  });

  final SnapshotImage image;
  final String title;

  @override
  State<SnapshotViewScreen> createState() => _SnapshotViewScreenState();
}

class _SnapshotViewScreenState extends State<SnapshotViewScreen> {
  var _saving = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MaicColors.bgTop,
        title: Text(widget.title.toUpperCase()),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: MaicBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              MaicPanel(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: InteractiveViewer(
                        child: Image.memory(
                          widget.image.bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'La imagen no se pudo mostrar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: MaicColors.muted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MaicPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'JPEG del servidor, no un fotograma del player.',
                      style: TextStyle(color: MaicColors.muted),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar en la galería'),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: MaicColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final allowed = await Gal.hasAccess() || await Gal.requestAccess();
      if (!allowed) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _message = 'Sin permiso para guardar en la galería.';
        });
        return;
      }
      await Gal.putImageBytes(widget.image.bytes, name: _fileName);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = 'Guardado en la galería.';
      });
    } on GalException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = switch (error.type) {
          GalExceptionType.accessDenied =>
            'Sin permiso para guardar en la galería.',
          GalExceptionType.notEnoughSpace =>
            'No hay espacio en el dispositivo.',
          GalExceptionType.notSupportedFormat =>
            'El formato de la imagen no se pudo guardar.',
          GalExceptionType.unexpected => 'No se pudo guardar la imagen.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = 'No se pudo guardar la imagen.';
      });
    }
  }

  String get _fileName {
    final stamp = (widget.image.timestampUtc ?? DateTime.now().toUtc())
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .split('.')
        .first;
    final channel = widget.image.channel;
    final safeTitle = widget.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final name = safeTitle.isEmpty ? 'snapshot' : safeTitle;
    return 'MAIC_${name}_ch${channel}_$stamp';
  }
}
