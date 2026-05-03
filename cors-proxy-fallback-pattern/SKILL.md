---
name: cors-proxy-fallback-pattern
description: 并发多代理 + 直连竞争策略解决静态网页 CORS 抓取问题，适用于 RSS/API 订阅源
category: web
---

# CORS Proxy Fallback Pattern

## When to Use
Fetch external API/RSS feeds from a static web app (GitHub Pages, etc.) where CORS blocks direct browser requests. Use when any single CORS proxy may be unreliable or slow.

## Core Problem
- Browser CORS blocks direct fetch to third-party origins
- Any single CORS proxy (allorigins, codetabs, corsproxy.io) may fail, timeout, or return wrong content for specific URLs
- Sequential fallback wastes time on slow/timeout proxies

## Solution: Parallel Race with Multiple Strategies

```typescript
const CORS_PROXIES = [
  'https://api.allorigins.win/raw?url=',
  'https://api.codetabs.com/v1/proxy?quest=',
];

async function fetchWithProxyFallback(url: string, options: RequestInit): Promise<Response> {
  const strategies: Array<() => Promise<Response>> = [
    // Strategy 1: Direct fetch (try first — many RSS feeds have no CORS issues)
    () => {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 8000);
      return fetch(url, { ...options, signal: controller.signal }).finally(() => clearTimeout(timeout));
    },
    // Strategy 2: allorigins proxy
    () => {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000);
      return fetch(`${CORS_PROXIES[0]}${encodeURIComponent(url)}`, { ...options, signal: controller.signal }).finally(() => clearTimeout(timeout));
    },
    // Strategy 3: codetabs proxy
    () => {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10000);
      return fetch(`${CORS_PROXIES[1]}${encodeURIComponent(url)}`, { ...options, signal: controller.signal }).finally(() => clearTimeout(timeout));
    },
  ];

  // Promise.allSettled — NOT Promise.race!
  // Promise.race: first rejection immediately throws, other promises keep running but result is already thrown
  // Promise.allSettled: waits for all, returns all results, then filter for success
  const settled = await Promise.all(
    strategies.map(async (strategy) => {
      try {
        const response = await strategy();
        return response.ok ? { ok: true, response } : { ok: false, response };
      } catch {
        return { ok: false, response: null };
      }
    })
  );

  const firstOk = settled.find((r) => r.ok);
  if (firstOk?.response) return firstOk.response;
  throw new Error('All fetch strategies failed');
}
```

## Key Pitfalls

### ❌ Promise.race is wrong for multi-success fallback
```typescript
// WRONG — first rejection throws immediately
const result = await Promise.race(strategies.map(s => s()));
// If strategy 1 (direct) throws CORS error, you never wait for proxy responses
```

```typescript
// CORRECT — all settle, then filter
const settled = await Promise.all(strategies.map(...));
const success = settled.find(r => r.ok);
```

### ❌ AbortSignal.timeout() unreliable in some browsers
```typescript
// Unreliable in some browser/environment combinations
fetch(url, { signal: AbortSignal.timeout(10000) });

// Always reliable
const controller = new AbortController();
setTimeout(() => controller.abort(), 10000);
fetch(url, { signal: controller.signal });
```

### ❌ Sequential fallback wastes time
```typescript
// WRONG — if allorigins takes 12s timeout, you wait 12s before trying next
const r1 = await fetchWithAllorigins(url);
if (!r1.ok) r1 = await fetchWithCodetabs(url);
if (!r1.ok) r1 = await fetchDirect(url);  // by now 20+ seconds wasted
```

## Verified Proxy Status (as of 2026-04-18)

| Proxy | hnrss.org | httpbin.org | Notes |
|-------|-----------|-------------|-------|
| Direct | ✅ (CORS blocked in browser) | ✅ | Try first, fastest when works |
| allorigins | ❌ timeout (~10s) | ✅ | Reliable for most URLs |
| codetabs | ❌ 301 empty body | ✅ | Follows redirects, may return empty |
| corsproxy.io | ❌ 403 | - | Unreliable |
| proxy.cors.sh | ❌ 400 | - | Unreliable |

## Timeout Strategy
- Direct fetch: 8s (likely works if no CORS issue)
- Proxy: 10s each (proxies are slower)
- Total max: ~10s (direct wins fast, proxy takes longer)

## Verification Steps
1. Deploy and test with `curl` first from server to check actual availability
2. Browser test: Network tab shows which strategy succeeded
3. Add per-fetch logging to show which proxy was used and how long it took
