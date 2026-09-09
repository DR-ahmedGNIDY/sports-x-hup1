import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/store_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/cart_controller.dart';
import '../application/coupon_controller.dart';
import '../domain/entities/cart_item.dart';
import 'widgets/money.dart';
import 'widgets/store_scaffold.dart';
import 'store_paths.dart';

class StoreCartPage extends ConsumerWidget {
  const StoreCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(cartControllerProvider);
    final subtotal = ref.watch(cartSubtotalMinorProvider);
    final discount = ref.watch(cartDiscountMinorProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (items.isEmpty) {
      return StoreScaffold(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.storeCartEmpty),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go(StorePaths.shop),
                child: Text(l10n.storeCartContinueShopping),
              ),
            ],
          ),
        ),
      );
    }

    return StoreScaffold(
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (context, index) => _CartLine(item: items[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            child: Column(
              children: [
                const _CouponField(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.storeSubtotal),
                    Text(formatMoney(subtotal, isArabic: isArabic)),
                  ],
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.storeDiscount),
                      Text(
                        '-${formatMoney(discount, isArabic: isArabic)}',
                        style: const TextStyle(color: StoreTheme.sale),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                // The fee is not knowable here — it depends on a
                // governorate the customer has not chosen yet.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.storeShippingCalculatedAtCheckout,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(StorePaths.checkout),
                    child: Text(l10n.storeCheckout),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends ConsumerWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cart = ref.read(cartControllerProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: item.imageUrl == null
                ? ColoredBox(
                    color: Theme.of(context).brightness == Brightness.light
                        ? StoreTheme.surfaceAlt
                        : StoreTheme.darkSurfaceAlt,
                    child: const SizedBox.expand(),
                  )
                : CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title.resolve(isArabic),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.variantLabel != null &&
                  item.variantLabel!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.variantLabel!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.remove,
                    onTap: () =>
                        cart.setQuantity(item.key, item.quantity - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('${item.quantity}'),
                  ),
                  _StepButton(
                    icon: Icons.add,
                    onTap: item.quantity >= maxLineQuantity
                        ? null
                        : () => cart.setQuantity(item.key, item.quantity + 1),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => cart.remove(item.key),
                    child: Text(l10n.storeRemove),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        MoneyText(
          priceMinor: item.lineTotalMinor,
          align: TextAlign.end,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// The discount-code row. Applied against the current subtotal, and dropped
/// the moment the basket changes: a percentage quoted at one basket size is
/// wrong at another, and showing a stale figure would be worse than asking
/// the customer to re-apply.
class _CouponField extends ConsumerStatefulWidget {
  const _CouponField();

  @override
  ConsumerState<_CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends ConsumerState<_CouponField> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coupon = ref.watch(couponControllerProvider);

    // Re-applying on every basket change would fire a request per tap of
    // the quantity stepper, so the code is dropped instead and the customer
    // re-applies once they have settled on what they are buying.
    ref.listen(cartSubtotalMinorProvider, (previous, next) {
      if (previous != null && previous != next && coupon.isApplied) {
        ref.read(couponControllerProvider.notifier).clear();
      }
    });

    if (coupon.isApplied) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${l10n.storeCouponApplied}: ${coupon.quote!.code}'),
          ),
          TextButton(
            onPressed: () {
              _code.clear();
              ref.read(couponControllerProvider.notifier).clear();
            },
            child: Text(l10n.storeCouponRemove),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l10n.storeCouponLabel,
                ),
                onSubmitted: (value) =>
                    ref.read(couponControllerProvider.notifier).apply(value),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: coupon.isChecking
                  ? null
                  : () => ref
                        .read(couponControllerProvider.notifier)
                        .apply(_code.text),
              child: coupon.isChecking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.storeCouponApply),
            ),
          ],
        ),
        if (coupon.error != null) ...[
          const SizedBox(height: 6),
          // The server's own wording: it distinguishes an expired code from
          // a basket below the minimum, and only one of those is solvable.
          Text(
            coupon.error!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
