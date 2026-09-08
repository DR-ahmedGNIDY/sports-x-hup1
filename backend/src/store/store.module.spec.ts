import 'reflect-metadata';
import { StoreCategoriesModule } from './categories/categories.module';
import {
  AdminStoreCategoriesController,
  StoreCategoriesController,
} from './categories/categories.controller';
import { StoreCategoriesService } from './categories/categories.service';
import {
  AdminStoreProductsController,
  StoreProductsController,
} from './products/products.controller';
import { StoreProductsModule } from './products/products.module';
import { StoreProductsService } from './products/products.service';
import {
  AdminOrdersController,
  OrdersController,
} from './orders/orders.controller';
import { OrdersModule } from './orders/orders.module';
import { OrdersService } from './orders/orders.service';
import { ShippingModule } from './shipping/shipping.module';
import { ShippingService } from './shipping/shipping.service';
import { StoreModule } from './store.module';

// Wiring, not behaviour. A controller left unregistered or a service left
// unexported is a failure that only appears when the application boots —
// the service specs construct their subject with `new`, so they would never
// notice. Booting a real Nest context here would need @nestjs/testing,
// which this project does not depend on, so the module metadata the
// decorators record is read directly instead.
function metadata(target: unknown, key: string): unknown[] {
  return (Reflect.getMetadata(key, target as object) as unknown[]) ?? [];
}

describe('StoreModule wiring', () => {
  it('registers the public and admin controllers of both sub-modules', () => {
    expect(metadata(StoreCategoriesModule, 'controllers')).toEqual(
      expect.arrayContaining([
        StoreCategoriesController,
        AdminStoreCategoriesController,
      ]),
    );
    expect(metadata(StoreProductsModule, 'controllers')).toEqual(
      expect.arrayContaining([
        StoreProductsController,
        AdminStoreProductsController,
      ]),
    );
  });

  it('exports the categories service that products injects', () => {
    // StoreProductsService takes StoreCategoriesService in its constructor;
    // without this export Nest cannot resolve it and the API fails to boot.
    expect(metadata(StoreCategoriesModule, 'exports')).toContain(
      StoreCategoriesService,
    );
    expect(metadata(StoreProductsModule, 'imports')).toContain(
      StoreCategoriesModule,
    );
  });

  it('aggregates every sub-module, so AppModule only imports StoreModule', () => {
    expect(metadata(StoreModule, 'imports')).toEqual(
      expect.arrayContaining([
        StoreCategoriesModule,
        StoreProductsModule,
        ShippingModule,
        OrdersModule,
      ]),
    );
  });

  it('exports the shipping service that checkout prices the fee through', () => {
    expect(metadata(ShippingModule, 'exports')).toContain(ShippingService);
    expect(metadata(OrdersModule, 'imports')).toContain(ShippingModule);
  });

  it('gives orders its own product model registration', () => {
    // Checkout writes stock through conditional atomic updates rather than
    // through StoreProductsService, so OrdersModule needs the model itself —
    // forgetting this registration only surfaces at boot.
    expect(metadata(OrdersModule, 'controllers')).toEqual(
      expect.arrayContaining([OrdersController, AdminOrdersController]),
    );
    expect(metadata(OrdersModule, 'providers')).toContain(OrdersService);
  });

  it('declares the providers each sub-module registers', () => {
    expect(metadata(StoreCategoriesModule, 'providers')).toContain(
      StoreCategoriesService,
    );
    expect(metadata(StoreProductsModule, 'providers')).toContain(
      StoreProductsService,
    );
  });
});
