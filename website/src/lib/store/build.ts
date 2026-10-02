import { API_BASE_URL } from '../settings';

// Build-time lists of the category and product slugs that exist now, so each
// gets a real page (and a sitemap entry). A slug added after the build is
// still served: nginx falls back to the generic shell under /store/c/ or
// /store/p/, which reads the slug from the URL. A failed fetch yields no
// extra pages rather than a failed build, for the same reason.

async function json<T>(path: string): Promise<T | null> {
  try {
    const res = await fetch(API_BASE_URL + path);
    return res.ok ? ((await res.json()) as T) : null;
  } catch {
    return null;
  }
}

export async function categorySlugs(): Promise<string[]> {
  const r = await json<{ items: { slug: string }[] }>('/store/categories');
  return r?.items.map((c) => c.slug) ?? [];
}

export async function productSlugs(): Promise<string[]> {
  const slugs: string[] = [];
  for (let page = 1; page <= 100; page++) {
    const r = await json<{ items: { slug: string }[]; page: number; pageSize: number; total: number }>(
      `/store/products?page=${page}`,
    );
    if (!r) break;
    slugs.push(...r.items.map((p) => p.slug));
    if (r.page * r.pageSize >= r.total) break;
  }
  return slugs;
}
