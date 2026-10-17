import 'package:flutter/material.dart';

import 'models/product.dart';
import 'repositories/product_note_repository.dart';
import 'services/product_service.dart';
import 'product_card.dart';
import 'product_detail_page.dart';

class ProductScreen extends StatefulWidget {
  final ProductNoteRepository noteRepository;

  const ProductScreen({
    super.key,
    required this.noteRepository,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late ProductService _service;
  late Future<List<Product>> _futureProducts;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    _service = ProductService(
      'https://raw.githubusercontent.com/Vict0rMMA/TALLER-MOVIL/main/data/products.json',
    );
    _futureProducts = _service.getProducts();
  }

  void retryProductList() {
    setState(() {
      _futureProducts = _service.getProducts();
    });
  }

  void openProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: product,
          noteRepository: widget.noteRepository,
        ),
      ),
    );
  }

  Future<void> syncPendingNotes() async {
    setState(() => _syncing = true);

    final (sent, failed) = await widget.noteRepository.syncPending();
    if (!mounted) return;

    setState(() => _syncing = false);

    String message;
    if (sent == 0 && failed == 0) {
      message = 'No hay notas pendientes por sincronizar';
    } else if (failed == 0) {
      message = 'Se sincronizaron $sent nota(s)';
    } else {
      message = 'Enviadas: $sent. Fallidas: $failed (siguen pendientes)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Vestidos de baño'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _syncing ? null : syncPendingNotes,
                      icon: _syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('Sincronizar pendientes'),
                    ),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No pudimos cargar el catálogo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: retryProductList,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Todavía no hay productos disponibles',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            return ProductCard(
              product: product,
              onTap: () {
                openProductDetail(product);
              },
            );
          },
        );
      },
    );
  }
}
