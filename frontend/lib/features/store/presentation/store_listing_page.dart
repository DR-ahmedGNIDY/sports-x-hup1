import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/breakpoints.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/catalog_providers.dart';
import 'widgets/product_card.dart';
import 'widgets/store_scaffold.dart';
import 'store_paths.dart';

/// The catalogue: a grid, sort control, and — when it was reached by
/// searching — a search field.
///
/// One screen serves the whole catalogue, a single category and a search
/// result, because on the backend they are one endpoint with different
/// query parameters. Three screens would be three copies of this grid.
class StoreListingPage extends ConsumerStatefulWidget {
  const StoreListingPage({
    super.key,
    this.categorySlug,
    this.showSearchField = false,
  });

  final String? categorySlug;
  final bool showSearchField;

  @override
  ConsumerState<StoreListingPage> createState() => _StoreListingPageState();
}

class _StoreListingPageState extends ConsumerState<StoreListingPage> {
  final _searchController = TextEditingController();
  String? _search;
  String? _sort;
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = ProductQuery(
      page: _page,
      search: _search,
      categorySlug: widget.categorySlug,
      sort: _sort,
    );
    final products = ref.watch(productListProvider(query));
    final columns = AppBreakpoints.isDesktop(context) ? 4 : 2;

    return StoreScaffold(
      child: Column(
        children: [
          if (widget.showSearchField)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.storeSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
                // Submitted rather than debounced-as-you-type: each keystroke
                // is a database query with a text index behind it, and the
                // customer here knows what they are looking for.
                onSubmitted: (value) => setState(() {
                  _search = value.trim().isEmpty ? null : value.trim();
                  _page = 1;
                }),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Spacer(),
                DropdownButton<String?>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  hint: Text(l10n.storeSortNewest),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.storeSortNewest),
                    ),
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Text(l10n.storeSortPriceAsc),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text(l10n.storeSortPriceDesc),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _sort = value;
                    _page = 1;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              data: (page) {
                if (page.items.isEmpty) {
                  return Center(child: Text(l10n.storeNoProducts));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 28,
                        // 3:4 image plus the name and price beneath it.
                        childAspectRatio: 0.58,
                      ),
                  itemCount: page.items.length,
                  itemBuilder: (context, index) {
                    final product = page.items[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.go(StorePaths.product(product.slug)),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.genericErrorMessage)),
            ),
          ),
          products.maybeWhen(
            data: (page) => _Pager(
              page: page.page,
              hasMore: page.hasMore,
              onChange: (next) => setState(() => _page = next),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.hasMore,
    required this.onChange,
  });

  final int page;
  final bool hasMore;
  final void Function(int page) onChange;

  @override
  Widget build(BuildContext context) {
    if (page == 1 && !hasMore) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: l10n.storePreviousPage,
            onPressed: page > 1 ? () => onChange(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$page'),
          IconButton(
            tooltip: l10n.storeNextPage,
            onPressed: hasMore ? () => onChange(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
