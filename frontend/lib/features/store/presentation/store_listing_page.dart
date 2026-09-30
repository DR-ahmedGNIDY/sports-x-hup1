import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/breakpoints.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/catalog_providers.dart';
import '../domain/entities/store_category.dart';
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
          _CategoryChips(currentSlug: widget.categorySlug),
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

/// The row of chips that walks the two-level catalogue: the departments
/// (Men / Women / Kids) at the top, and inside one of them the shelves it
/// holds (Clothing / Shoes / Equipment).
///
/// It navigates rather than filtering in place — each chip is a category URL
/// the customer can bookmark or share, and the grid above already rebuilds
/// from the route's slug. Which level it shows follows from where the
/// customer is, so one widget serves `/store/shop`, a department and a shelf.
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.currentSlug});

  /// Null on `/store/shop`, where the whole catalogue is listed.
  final String? currentSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // A failed or pending nav is not worth a spinner or an error above the
    // grid: the products are the page, and the chips are a shortcut.
    final categories = ref.watch(storeCategoriesProvider).valueOrNull;
    if (categories == null) return const SizedBox.shrink();

    StoreCategory? current;
    for (final category in categories) {
      if (category.slug == currentSlug) current = category;
    }

    // Standing on a shelf, the useful siblings are the other shelves of the
    // same department — not the other departments.
    final String? departmentId = current == null
        ? null
        : (current.parentId ?? current.id);
    StoreCategory? department;
    for (final category in categories) {
      if (category.id == departmentId) department = category;
    }

    final siblings = categories
        .where((item) => item.parentId == departmentId)
        .toList();
    if (siblings.isEmpty) return const SizedBox.shrink();

    // "All" means the whole catalogue at the top level, and the whole
    // department once inside one.
    final allLabel = department == null
        ? l10n.storeAllProducts
        : l10n.storeAllInCategory(department.name.resolve(isArabic));
    final allSelected = current == null || current.id == departmentId;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          ChoiceChip(
            label: Text(allLabel),
            selected: allSelected,
            onSelected: (_) => context.go(
              department == null
                  ? StorePaths.shop
                  : StorePaths.category(department.slug),
            ),
          ),
          for (final sibling in siblings)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: ChoiceChip(
                label: Text(sibling.name.resolve(isArabic)),
                selected: sibling.id == current?.id,
                onSelected: (_) =>
                    context.go(StorePaths.category(sibling.slug)),
              ),
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
