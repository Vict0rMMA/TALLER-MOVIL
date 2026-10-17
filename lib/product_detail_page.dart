import 'package:flutter/material.dart';

import 'models/product.dart';
import 'models/product_note.dart';
import 'repositories/product_note_repository.dart';
import 'product_card.dart';

bool isPriorityValid(int p) => p >= 2;

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final ProductNoteRepository noteRepository;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.noteRepository,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final TextEditingController _noteController = TextEditingController();
  int _priority = 1;

  ProductNote? _savedNote;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLocalNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalNote() async {
    final saved = await widget.noteRepository
        .getNoteForProduct(widget.product.id);
    if (!mounted) return;

    setState(() {
      _savedNote = saved;
      _loading = false;
      if (saved != null) {
        _noteController.text = saved.note;
        _priority = saved.priority;
      }
    });
  }

  Future<void> _saveLocalNote() async {
    final text = _noteController.text.trim();
    final priority = _priority;

    if (!isPriorityValid(priority)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La prioridad debe ser mínimo 2 para poder guardar'),
        ),
      );
      return;
    }

    final note = ProductNote(
      productId: widget.product.id,
      note: text,
      priority: priority,
      updatedAt: DateTime.now(),
    );

    setState(() => _saving = true);

    await widget.noteRepository.saveNote(note);
    if (!mounted) return;

    final saved = await widget.noteRepository
        .getNoteForProduct(widget.product.id);
    if (!mounted) return;

    setState(() {
      _savedNote = saved;
      _saving = false;
    });

    final message = saved != null && !saved.pendingSync
        ? 'Nota guardada y sincronizada'
        : 'Nota guardada en el dispositivo, pendiente de sincronizar';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSyncStatus(ColorScheme colors) {
    if (_loading) {
      return const Text('Cargando...');
    }

    final saved = _savedNote;

    if (saved == null) {
      return Chip(
        avatar: const Icon(Icons.info_outline, size: 18),
        label: const Text('No hay información guardada'),
        side: BorderSide.none,
        backgroundColor: colors.surfaceContainerHighest,
      );
    }

    if (saved.pendingSync) {
      return Chip(
        avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
        label: const Text('Pendiente'),
        side: BorderSide.none,
        backgroundColor: colors.tertiaryContainer,
      );
    }

    return Chip(
      avatar: const Icon(Icons.cloud_done_outlined, size: 18),
      label: const Text('Sincronizado'),
      side: BorderSide.none,
      backgroundColor: colors.secondaryContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final product = widget.product;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return ColoredBox(
                                color: colors.surfaceContainerHighest,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 64,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.category_outlined, size: 18),
                        label: Text(product.category),
                        side: BorderSide.none,
                        backgroundColor: colors.secondaryContainer,
                      ),
                      Chip(
                        avatar: const Icon(Icons.sell_outlined, size: 18),
                        label: Text(formatPrice(product.price)),
                        side: BorderSide.none,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mi nota',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildSyncStatus(colors),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Prioridad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return ChoiceChip(
                        label: Text('$value'),
                        selected: _priority == value,
                        onSelected: (_) {
                          setState(() => _priority = value);
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Nota personal',
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveLocalNote,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar nota'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
