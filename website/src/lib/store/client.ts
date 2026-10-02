// The storefront's browser side. Every store page is a static shell; this
// module reads `data-store-page` on <main> and renders that page from the
// live API, so prices, stock and new products never wait for a rebuild.
//
// It talks to the same public endpoints the app's storefront used:
// /store/categories, /store/products, /store/banners, /store/shipping-zones,
// /store/coupons/preview, /store/orders (guest) and /store/orders/track.

import type { StoreDict } from './strings';

type Lang = 'ar' | 'en';
type L10n = { en: string; ar?: string };
interface Image { publicId: string; secureUrl: string; colour?: string }
interface Colour { name: string; hex: string }
interface Category { id: string; name: L10n; slug: string; parentId?: string; image?: Image; sortOrder: number }
interface Card {
  id: string; title: L10n; slug: string; priceMinor: number; compareAtPriceMinor?: number;
  image?: Image; badge?: 'new' | 'pre_order' | 'sale'; inStock: boolean; colours?: Colour[];
}
interface Variant { id: string; size?: string; colour?: string; sku?: string; inStock: boolean }
interface Product extends Card { description?: L10n; categoryId: string; images: Image[]; variants: Variant[] }
interface Page<T> { items: T[]; page: number; pageSize: number; total: number }
interface Zone { id: string; name: L10n; code: string; feeMinor: number }
interface Banner { id: string; desktopUrl: string; mobileUrl?: string; alt?: L10n }
interface Order {
  orderNumber: string; email: string; status: keyof StoreDict['status'];
  lines: { title: L10n; size?: string; colour?: string; imageUrl?: string; quantity: number; unitPriceMinor: number }[];
  address: { fullName: string; phone: string; governorateName?: L10n; city: string; street: string };
  subtotalMinor: number; shippingFeeMinor: number; discountMinor?: number; couponCode?: string; totalMinor: number;
}
export interface CartLine {
  productId: string; variantId: string; slug: string; title: L10n; imageUrl?: string;
  size?: string; colour?: string; unitPriceMinor: number; quantity: number;
}

const main = document.querySelector<HTMLElement>('main[data-store-page]')!;
const lang = main.dataset.lang as Lang;
const api = main.dataset.api!;
const base = lang === 'ar' ? '/store' : '/en/store';
const s: StoreDict = JSON.parse(document.getElementById('store-strings')!.textContent!);

// ---------- helpers ----------

const esc = (v: unknown) =>
  String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
const loc = (t?: L10n) => (t ? (lang === 'ar' && t.ar ? t.ar : t.en) : '');
const money = (minor: number) =>
  new Intl.NumberFormat(lang === 'ar' ? 'ar-EG-u-nu-latn' : 'en-EG', { style: 'currency', currency: 'EGP', maximumFractionDigits: minor % 100 ? 2 : 0 }).format(minor / 100);
/// Cloudinary resizes on the fly; a 2000px upload should not ship to a tile.
const img = (url: string | undefined, w: number) =>
  url ? url.replace('/upload/', `/upload/w_${w},c_limit,f_auto,q_auto/`) : '';
const $ = <T extends HTMLElement = HTMLElement>(sel: string, root: ParentNode = document) => root.querySelector<T>(sel)!;

class ApiError extends Error {
  constructor(public status: number, message: string) { super(message); }
}
async function call<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(api + path, {
    ...init,
    headers: init?.body ? { 'Content-Type': 'application/json' } : undefined,
  });
  if (!res.ok) {
    let message = s.error;
    try {
      const body = await res.json();
      message = Array.isArray(body.message) ? body.message[0] : body.message || message;
    } catch { /* keep the generic message */ }
    throw new ApiError(res.status, message);
  }
  return res.json();
}

// ---------- cart (this browser only) ----------

const CART_KEY = 'sxh-cart-v1';
function readCart(): CartLine[] {
  try { return JSON.parse(localStorage.getItem(CART_KEY) || '[]'); } catch { return []; }
}
function writeCart(lines: CartLine[]) {
  try { localStorage.setItem(CART_KEY, JSON.stringify(lines)); } catch { /* private mode */ }
  updateCartBadge();
}
function updateCartBadge() {
  const count = readCart().reduce((n, l) => n + l.quantity, 0);
  document.querySelectorAll<HTMLElement>('[data-cart-count]').forEach((el) => {
    el.textContent = String(count);
    el.hidden = count === 0;
  });
}
const subtotalOf = (lines: CartLine[]) => lines.reduce((n, l) => n + l.unitPriceMinor * l.quantity, 0);

// ---------- shared renderers ----------

function cardHtml(p: Card) {
  const sale = p.compareAtPriceMinor && p.compareAtPriceMinor > p.priceMinor;
  return `<a class="pcard" href="${base}/p/${encodeURIComponent(p.slug)}">
    <div class="pimg">${p.image ? `<img src="${esc(img(p.image.secureUrl, 500))}" alt="${esc(loc(p.title))}" loading="lazy">` : ''}
      ${p.badge ? `<span class="pbadge ${p.badge}">${esc(s.badge[p.badge])}</span>` : ''}
      ${!p.inStock ? `<span class="pbadge out">${esc(s.soldOut)}</span>` : ''}</div>
    <div class="pinfo"><b>${esc(loc(p.title))}</b>
      <span class="price">${money(p.priceMinor)}${sale ? ` <s>${money(p.compareAtPriceMinor!)}</s>` : ''}</span>
      ${swatchRow(p.colours)}</div>
  </a>`;
}

/// The colours a product comes in, as small dots under its tile.
function swatchRow(colours?: Colour[]) {
  if (!colours?.length) return '';
  const shown = colours.slice(0, 6);
  const more = colours.length - shown.length;
  return `<span class="swatches" aria-label="${esc(s.colour)}: ${esc(colours.map((c) => c.name).join('، '))}">${shown
    .map((c) => `<i style="background:${esc(c.hex)}" title="${esc(c.name)}"></i>`)
    .join('')}${more > 0 ? `<em>+${more}</em>` : ''}</span>`;
}
const skeleton = (n: number) => Array.from({ length: n }, () => '<div class="pcard sk"><div class="pimg"></div><div class="pinfo"><i></i><i></i></div></div>').join('');
const errorBox = (msg: string = s.error) => `<p class="st-msg err">${esc(msg)}</p>`;

let categoriesCache: Promise<Category[]> | undefined;
const categories = () => (categoriesCache ??= call<{ items: Category[] }>('/store/categories').then((r) => r.items));

// ---------- pages ----------

async function home() {
  const deptEl = $('#depts');
  call<{ items: Banner[] }>('/store/banners').then(({ items }) => {
    const b = items[0];
    if (!b) return;
    $('#banner').innerHTML = `<picture>${b.mobileUrl ? `<source media="(max-width:700px)" srcset="${esc(img(b.mobileUrl, 800))}">` : ''}
      <img src="${esc(img(b.desktopUrl, 1600))}" alt="${esc(loc(b.alt))}"></picture>`;
    $('#banner').hidden = false;
  }).catch(() => {});

  try {
    const all = await categories();
    const depts = all.filter((c) => !c.parentId).sort((a, b) => a.sortOrder - b.sortOrder);
    deptEl.innerHTML = depts.map((d) => {
      const kids = all.filter((c) => c.parentId === d.id).sort((a, b) => a.sortOrder - b.sortOrder);
      return `<article class="dept">
        <a class="pic" href="${base}/c/${d.slug}" style="background-image:url('${esc(img(d.image?.secureUrl, 700))}')"><h3>${esc(loc(d.name))}</h3></a>
        <div class="subs">${kids.map((k) => `<a href="${base}/c/${k.slug}"><span>${esc(subName(k, d))}</span><em>${lang === 'ar' ? '←' : '→'}</em></a>`).join('')}
          <a href="${base}/c/${d.slug}"><span>${esc(s.allIn)} ${esc(loc(d.name))}</span><em>${lang === 'ar' ? '←' : '→'}</em></a></div>
      </article>`;
    }).join('');
  } catch { deptEl.innerHTML = errorBox(); }

  for (const [id, query] of [['#featured', 'featured=true'], ['#newest', 'sort=newest']] as const) {
    const el = $(id);
    el.innerHTML = skeleton(4);
    call<Page<Card>>(`/store/products?${query}&page=1`)
      .then((r) => {
        const items = r.items.slice(0, 8);
        if (!items.length) { el.closest('section')!.hidden = true; return; }
        el.innerHTML = items.map(cardHtml).join('');
      })
      .catch(() => { el.closest('section')!.hidden = true; });
  }
}

/// "Men's Clothing" under "Men" reads as just "Clothing" in that department's
/// list; the full name stays on the category page itself.
function subName(child: Category, parent: Category) {
  const full = loc(child.name);
  const p = loc(parent.name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const trimmed = lang === 'ar' ? full.replace(new RegExp(`\\s*${p}$`), '') : full.replace(new RegExp(`^${p}'?s?\\s*`), '');
  return trimmed || full;
}

/// Category pages and the "all products" page share one listing.
async function listing(kind: 'category' | 'shop') {
  const grid = $('#grid');
  const more = $<HTMLButtonElement>('#more');
  const sortEl = $<HTMLSelectElement>('#sort');
  const params = new URLSearchParams(location.search);
  let slug = '';

  if (kind === 'category') {
    slug = slugFromPath('c');
    try {
      const all = await categories();
      const cat = all.find((c) => c.slug === slug);
      if (!cat) { $('#title').textContent = s.noProducts; grid.innerHTML = ''; return; }
      const parent = cat.parentId ? all.find((c) => c.id === cat.parentId) : cat;
      $('#title').textContent = loc(cat.name);
      document.title = `${loc(cat.name)} | ${s.title}`;
      const siblings = all.filter((c) => c.parentId === parent!.id).sort((a, b) => a.sortOrder - b.sortOrder);
      $('#chips').innerHTML = [parent!, ...siblings].map((c) =>
        `<a class="chip${c.slug === slug ? ' on' : ''}" href="${base}/c/${c.slug}">${esc(c === parent ? `${s.allIn} ${loc(c.name)}` : subName(c, parent!))}</a>`).join('');
    } catch { grid.innerHTML = errorBox(); return; }
  } else {
    const q = params.get('q') || '';
    const input = $<HTMLInputElement>('#q');
    input.value = q;
  }

  sortEl.value = params.get('sort') || 'newest';
  sortEl.addEventListener('change', () => {
    params.set('sort', sortEl.value);
    location.search = params.toString();
  });

  let page = 1;
  async function load(append: boolean) {
    const qs = new URLSearchParams({ page: String(page), sort: sortEl.value });
    if (slug) qs.set('categorySlug', slug);
    if (params.get('q')) qs.set('search', params.get('q')!);
    if (!append) grid.innerHTML = skeleton(8);
    more.disabled = true;
    try {
      const r = await call<Page<Card>>(`/store/products?${qs}`);
      const html = r.items.map(cardHtml).join('');
      grid.innerHTML = append ? grid.innerHTML + html : html || `<p class="st-msg">${esc(s.noProducts)}</p>`;
      more.hidden = r.page * r.pageSize >= r.total;
    } catch { grid.innerHTML = errorBox(); more.hidden = true; }
    more.disabled = false;
  }
  more.addEventListener('click', () => { page += 1; load(true); });
  load(false);
}

function slugFromPath(segment: 'c' | 'p') {
  const parts = location.pathname.replace(/\/$/, '').split('/');
  const i = parts.lastIndexOf(segment);
  return decodeURIComponent(i >= 0 && parts[i + 1] ? parts[i + 1] : new URLSearchParams(location.search).get('s') || '');
}

async function product() {
  const root = $('#product');
  const slug = slugFromPath('p');
  let p: Product;
  try {
    p = await call<Product>(`/store/products/${encodeURIComponent(slug)}`);
  } catch (e) {
    root.innerHTML = errorBox(e instanceof ApiError && e.status === 404 ? s.notFound : s.error) +
      `<a class="cta" href="${base}">${esc(s.backToStore)}</a>`;
    return;
  }
  document.title = `${loc(p.title)} | ${s.title}`;
  const sizes = [...new Set(p.variants.map((v) => v.size).filter(Boolean))] as string[];
  // Colours in the merchant's order, with their shades; a product saved
  // before colours had shades falls back to the names on its variants.
  const palette: Colour[] = p.colours?.length
    ? p.colours
    : ([...new Set(p.variants.map((v) => v.colour).filter(Boolean))] as string[]).map((name) => ({ name, hex: '' }));
  const colours = palette.map((c) => c.name);
  let size = sizes.length === 1 ? sizes[0] : '';
  // Open on the first colour that can actually be bought, so the photos
  // and the button match something in stock.
  let colour =
    colours.find((c) => p.variants.some((v) => v.colour === c && v.inStock)) ?? colours[0] ?? '';
  const sale = p.compareAtPriceMinor && p.compareAtPriceMinor > p.priceMinor;
  const allImages = p.images.length ? p.images : p.image ? [p.image] : [];
  /// The photos for a colour: its own first, then the general ones. A
  /// colour with no photos of its own shows the general set (or everything).
  const imagesFor = (c: string) => {
    const own = allImages.filter((i) => c && i.colour === c);
    const general = allImages.filter((i) => !i.colour);
    const set = [...own, ...general];
    return set.length ? set : allImages;
  };
  let images = imagesFor(colour);

  root.innerHTML = `
    <div class="gallery" id="gallery"></div>
    <div class="pdetail">
      ${p.badge ? `<span class="pbadge static ${p.badge}">${esc(s.badge[p.badge])}</span>` : ''}
      <h1>${esc(loc(p.title))}</h1>
      <div class="price big">${money(p.priceMinor)}${sale ? ` <s>${money(p.compareAtPriceMinor!)}</s>` : ''}</div>
      ${sizes.length ? `<div class="opt"><span>${esc(s.size)}</span><div class="opts" id="sizes">${sizes.map((x) => `<button type="button" data-v="${esc(x)}">${esc(x)}</button>`).join('')}</div></div>` : ''}
      ${palette.length ? `<div class="opt"><span>${esc(s.colour)}: <b id="colourname"></b></span><div class="opts swatch-opts" id="colours">${palette
        .map((c) => c.hex
          ? `<button type="button" class="swatch" data-v="${esc(c.name)}" title="${esc(c.name)}" aria-label="${esc(c.name)}"><i style="background:${esc(c.hex)}"></i></button>`
          : `<button type="button" data-v="${esc(c.name)}">${esc(c.name)}</button>`)
        .join('')}</div></div>` : ''}
      <div class="opt"><span>${esc(s.quantity)}</span><div class="qty"><button type="button" id="qminus" aria-label="-">−</button><output id="qty">1</output><button type="button" id="qplus" aria-label="+">+</button></div></div>
      <button class="cta add" id="add" type="button"></button>
      <p class="st-msg" id="addmsg" hidden></p>
      <ul class="perks">${s.perks.map((x) => `<li>${esc(x)}</li>`).join('')}</ul>
      ${p.description ? `<div class="desc">${esc(loc(p.description)).replace(/\n/g, '<br>')}</div>` : ''}
    </div>`;

  const gallery = $('#gallery');
  function renderGallery() {
    gallery.innerHTML = `
      <div class="gmain">${images[0] ? `<img id="gimg" src="${esc(img(images[0].secureUrl, 1000))}" alt="${esc(loc(p.title))}${colour ? ` — ${esc(colour)}` : ''}">` : ''}</div>
      ${images.length > 1 ? `<div class="thumbs">${images.map((im, i) => `<button type="button" data-i="${i}" class="${i ? '' : 'on'}"><img src="${esc(img(im.secureUrl, 160))}" alt=""></button>`).join('')}</div>` : ''}`;
  }
  gallery.addEventListener('click', (e) => {
    const b = (e.target as HTMLElement).closest<HTMLButtonElement>('.thumbs button');
    if (!b) return;
    gallery.querySelectorAll('.thumbs button').forEach((x) => x.classList.remove('on'));
    b.classList.add('on');
    $<HTMLImageElement>('#gimg').src = img(images[Number(b.dataset.i)].secureUrl, 1000);
  });
  renderGallery();

  let qty = 1;
  const variant = () => p.variants.find((v) => (!sizes.length || v.size === size) && (!colours.length || v.colour === colour));
  const addBtn = $<HTMLButtonElement>('#add');
  function refresh() {
    const avail = (opt: 'size' | 'colour', value: string) =>
      p.variants.some((v) => v[opt] === value && v.inStock && (opt === 'size' ? !colour || v.colour === colour : !size || v.size === size));
    root.querySelectorAll<HTMLButtonElement>('#sizes button').forEach((b) => {
      b.classList.toggle('on', b.dataset.v === size);
      b.classList.toggle('na', !avail('size', b.dataset.v!));
    });
    root.querySelectorAll<HTMLButtonElement>('#colours button').forEach((b) => {
      b.classList.toggle('on', b.dataset.v === colour);
      b.classList.toggle('na', !avail('colour', b.dataset.v!));
    });
    const nameEl = root.querySelector('#colourname');
    if (nameEl) nameEl.textContent = colour;
    $('#qty').textContent = String(qty);
    const v = variant();
    if (sizes.length && !size) { addBtn.textContent = s.selectSize; addBtn.disabled = true; }
    else if (colours.length && !colour) { addBtn.textContent = s.selectColour; addBtn.disabled = true; }
    else if (!v || !v.inStock) { addBtn.textContent = s.soldOut; addBtn.disabled = true; }
    else { addBtn.textContent = `${s.addToBag} · ${money(p.priceMinor * qty)}`; addBtn.disabled = false; }
  }
  root.querySelector('#sizes')?.addEventListener('click', (e) => {
    const b = (e.target as HTMLElement).closest('button'); if (!b) return; size = b.dataset.v!; refresh();
  });
  root.querySelector('#colours')?.addEventListener('click', (e) => {
    const b = (e.target as HTMLElement).closest('button'); if (!b) return;
    colour = b.dataset.v!;
    // The photos follow the colour.
    images = imagesFor(colour);
    renderGallery();
    refresh();
  });
  $('#qminus').addEventListener('click', () => { qty = Math.max(1, qty - 1); refresh(); });
  $('#qplus').addEventListener('click', () => { qty = Math.min(50, qty + 1); refresh(); });
  addBtn.addEventListener('click', () => {
    const v = variant(); if (!v) return;
    const lines = readCart();
    const existing = lines.find((l) => l.variantId === v.id);
    if (existing) existing.quantity = Math.min(50, existing.quantity + qty);
    else lines.push({
      productId: p.id, variantId: v.id, slug: p.slug, title: p.title, imageUrl: imagesFor(v.colour ?? '')[0]?.secureUrl,
      size: v.size, colour: v.colour, unitPriceMinor: p.priceMinor, quantity: qty,
    });
    writeCart(lines);
    const msg = $('#addmsg');
    msg.innerHTML = `${esc(s.addedToBag)} · <a href="${base}/cart">${esc(s.viewBag)}</a>`;
    msg.hidden = false;
  });
  refresh();
}

function summaryHtml(sub: number, discount: number, ship: number | null) {
  return `<div class="sumrow"><span>${esc(s.subtotal)}</span><b>${money(sub)}</b></div>
    ${discount ? `<div class="sumrow disc"><span>${esc(s.discount)}</span><b>−${money(discount)}</b></div>` : ''}
    <div class="sumrow"><span>${esc(s.shippingFee)}</span><b>${ship == null ? esc(s.shippingAtCheckout) : money(ship)}</b></div>
    <div class="sumrow total"><span>${esc(s.total)}</span><b>${money(sub - discount + (ship ?? 0))}</b></div>`;
}

function cart() {
  const root = $('#cart');
  function render() {
    const lines = readCart();
    if (!lines.length) {
      root.innerHTML = `<div class="empty"><p>${esc(s.cartEmpty)}</p><a class="cta" href="${base}">${esc(s.continueShopping)}</a></div>`;
      return;
    }
    root.innerHTML = `<div class="lines">${lines.map((l, i) => `
      <div class="line">
        <a class="limg" href="${base}/p/${encodeURIComponent(l.slug)}">${l.imageUrl ? `<img src="${esc(img(l.imageUrl, 200))}" alt="">` : ''}</a>
        <div class="linfo"><a href="${base}/p/${encodeURIComponent(l.slug)}"><b>${esc(loc(l.title))}</b></a>
          <small>${[l.size, l.colour].filter(Boolean).map(esc).join(' · ')}</small>
          <div class="qty sm"><button type="button" data-i="${i}" data-d="-1" aria-label="-">−</button><output>${l.quantity}</output><button type="button" data-i="${i}" data-d="1" aria-label="+">+</button></div>
        </div>
        <div class="lend"><b>${money(l.unitPriceMinor * l.quantity)}</b><button type="button" class="link" data-rm="${i}">${esc(s.remove)}</button></div>
      </div>`).join('')}</div>
      <aside class="summary">${summaryHtml(subtotalOf(lines), 0, null)}
        <a class="cta full" href="${base}/checkout">${esc(s.checkout)}</a>
        <a class="link center" href="${base}">${esc(s.continueShopping)}</a></aside>`;
  }
  root.addEventListener('click', (e) => {
    const t = (e.target as HTMLElement).closest<HTMLElement>('button'); if (!t) return;
    const lines = readCart();
    if (t.dataset.rm != null) lines.splice(Number(t.dataset.rm), 1);
    else if (t.dataset.d) {
      const l = lines[Number(t.dataset.i)];
      l.quantity = Math.min(50, Math.max(1, l.quantity + Number(t.dataset.d)));
    }
    writeCart(lines);
    render();
  });
  render();
}

async function checkout() {
  const root = $('#checkout');
  const lines = readCart();
  if (!lines.length) { location.href = `${base}/cart`; return; }
  const form = $<HTMLFormElement>('#cform');
  const gov = $<HTMLSelectElement>('#c-gov');
  const sumEl = $('#csum');
  const status = $('#cstatus');
  let zones: Zone[] = [];
  let coupon: { code: string; discountMinor: number } | null = null;
  const sub = subtotalOf(lines);

  const linesHtml = lines.map((l) => `<div class="mini"><span>${l.quantity}×</span><span>${esc(loc(l.title))}<small>${[l.size, l.colour].filter(Boolean).map(esc).join(' · ')}</small></span><b>${money(l.unitPriceMinor * l.quantity)}</b></div>`).join('');
  function renderSum() {
    const zone = zones.find((z) => z.code === gov.value);
    sumEl.innerHTML = linesHtml + summaryHtml(sub, coupon?.discountMinor ?? 0, zone ? zone.feeMinor : null);
  }
  try {
    zones = (await call<{ items: Zone[] }>('/store/shipping-zones')).items;
    gov.innerHTML = `<option value="">${esc(s.chooseGovernorate)}</option>` + zones.map((z) => `<option value="${esc(z.code)}">${esc(loc(z.name))}</option>`).join('');
  } catch { status.innerHTML = errorBox(); }
  gov.addEventListener('change', renderSum);
  renderSum();

  const couponInput = $<HTMLInputElement>('#c-coupon');
  const couponBtn = $<HTMLButtonElement>('#c-apply');
  const couponMsg = $('#c-couponmsg');
  couponBtn.addEventListener('click', async () => {
    if (coupon) { coupon = null; couponInput.disabled = false; couponInput.value = ''; couponBtn.textContent = s.couponApply; couponMsg.textContent = ''; renderSum(); return; }
    const code = couponInput.value.trim(); if (!code) return;
    couponBtn.disabled = true;
    try {
      coupon = await call('/store/coupons/preview', { method: 'POST', body: JSON.stringify({ code, subtotalMinor: sub }) });
      couponInput.disabled = true;
      couponBtn.textContent = s.couponRemove;
      couponMsg.className = 'fmsg ok';
      couponMsg.textContent = s.couponApplied;
    } catch (e) {
      couponMsg.className = 'fmsg err';
      couponMsg.textContent = e instanceof Error ? e.message : s.error;
    }
    couponBtn.disabled = false;
    renderSum();
  });

  const phoneRe = /^(\+20|0)?1[0125][0-9]{8}$/;
  const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const data = Object.fromEntries(new FormData(form)) as Record<string, string>;
    const checks: [string, string | null][] = [
      ['fullName', data.fullName?.trim() ? null : s.required],
      ['phone', phoneRe.test(data.phone?.replace(/\s/g, '') ?? '') ? null : s.invalidPhone],
      ['email', emailRe.test(data.email?.trim() ?? '') ? null : s.invalidEmail],
      ['governorateCode', data.governorateCode ? null : s.required],
      ['city', data.city?.trim() ? null : s.required],
      ['street', data.street?.trim() ? null : s.required],
    ];
    let first: HTMLElement | null = null;
    for (const [name, err] of checks) {
      const field = form.elements.namedItem(name) as HTMLInputElement;
      const msg = field.parentElement!.querySelector('.fmsg')!;
      msg.textContent = err ?? '';
      field.setAttribute('aria-invalid', String(Boolean(err)));
      if (err && !first) first = field;
    }
    if (first) { first.focus(); return; }

    const btn = $<HTMLButtonElement>('#c-submit');
    btn.disabled = true;
    btn.textContent = s.placing;
    status.innerHTML = '';
    try {
      const order = await call<Order>('/store/orders', {
        method: 'POST',
        body: JSON.stringify({
          email: data.email.trim(),
          lines: lines.map((l) => ({ productId: l.productId, variantId: l.variantId, quantity: l.quantity })),
          address: {
            fullName: data.fullName.trim(), phone: data.phone.replace(/\s/g, ''),
            governorateCode: data.governorateCode, city: data.city.trim(), street: data.street.trim(),
            ...(data.notes?.trim() ? { notes: data.notes.trim() } : {}),
          },
          ...(coupon ? { couponCode: coupon.code } : {}),
        }),
      });
      writeCart([]);
      try { sessionStorage.setItem('sxh-last-order', JSON.stringify(order)); } catch { /* fine */ }
      location.href = `${base}/order?n=${encodeURIComponent(order.orderNumber)}`;
    } catch (err) {
      status.innerHTML = errorBox(err instanceof Error ? err.message : s.error);
      btn.disabled = false;
      btn.textContent = s.placeOrder;
    }
  });
  root.hidden = false;
}

function orderHtml(o: Order, placed: boolean) {
  return `${placed ? `<div class="placed"><span class="tick">✓</span><h2>${esc(s.orderPlaced)}</h2>
      <p>${esc(s.orderNumberIs)}</p><div class="onum">${esc(o.orderNumber)}</div><p class="note">${esc(s.keepNumber)}</p></div>` : ''}
    <div class="ocard">
      <div class="ohead"><span>${esc(s.orderNumber)}: <b dir="ltr">${esc(o.orderNumber)}</b></span><span class="ostatus ${o.status}">${esc(s.status[o.status])}</span></div>
      <h3>${esc(s.items)}</h3>
      ${o.lines.map((l) => `<div class="mini">${l.imageUrl ? `<img src="${esc(img(l.imageUrl, 120))}" alt="">` : '<span></span>'}<span>${l.quantity}× ${esc(loc(l.title))}<small>${[l.size, l.colour].filter(Boolean).map(esc).join(' · ')}</small></span><b>${money(l.unitPriceMinor * l.quantity)}</b></div>`).join('')}
      <div class="sumbox">${summaryHtml(o.subtotalMinor, o.discountMinor ?? 0, o.shippingFeeMinor)}</div>
      <h3>${esc(s.deliverTo)}</h3>
      <p class="addr">${esc(o.address.fullName)} · <span dir="ltr">${esc(o.address.phone)}</span><br>${esc(o.address.street)}، ${esc(o.address.city)}، ${esc(loc(o.address.governorateName))}</p>
      <p class="addr">${esc(s.payment)}: ${esc(s.cod)}</p>
    </div>`;
}

function order() {
  const root = $('#order');
  const num = new URLSearchParams(location.search).get('n') || '';
  let o: Order | null = null;
  try { o = JSON.parse(sessionStorage.getItem('sxh-last-order') || 'null'); } catch { /* none */ }
  if (o && o.orderNumber === num) root.innerHTML = orderHtml(o, true);
  else location.href = `${base}/track?n=${encodeURIComponent(num)}`;
}

function track() {
  const form = $<HTMLFormElement>('#tform');
  const out = $('#tresult');
  const n = new URLSearchParams(location.search).get('n');
  if (n) (form.elements.namedItem('orderNumber') as HTMLInputElement).value = n;
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!form.reportValidity()) return;
    const data = Object.fromEntries(new FormData(form)) as Record<string, string>;
    const btn = form.querySelector('button')!;
    btn.disabled = true;
    try {
      const o = await call<Order>('/store/orders/track', {
        method: 'POST', body: JSON.stringify({ orderNumber: data.orderNumber.trim(), email: data.email.trim() }),
      });
      out.innerHTML = orderHtml(o, false);
    } catch (err) {
      out.innerHTML = errorBox(err instanceof ApiError && err.status === 404 ? s.orderNotFound : err instanceof Error ? err.message : s.error);
    }
    btn.disabled = false;
  });
}

// ---------- boot ----------

updateCartBadge();
window.addEventListener('storage', (e) => { if (e.key === CART_KEY) updateCartBadge(); });
({ home, category: () => listing('category'), shop: () => listing('shop'), product, cart, checkout, order, track } as Record<string, () => unknown>)[
  main.dataset.storePage!
]?.();
