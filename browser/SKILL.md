---
name: browser
description: Web browsing and interaction via Windows Edge — navigate, screenshot, fill forms, extract content. Used for scraping, research, QA, and automated web tasks.
version: 1.0.0
metadata:
  hermes:
    tags: [browser, web, edge, scraping, research]
    related_skills: [dogfood, github]
---

# Browser: Web Interaction via Windows Edge

## Overview

Use this skill for web browsing, content extraction, form filling, screenshot capture, and automated web interactions. The browser runs on Windows via WSL bridge and uses Microsoft Edge.

## Prerequisites

- Browser toolset available (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_type`, `browser_vision`, `browser_console`, `browser_scroll`, `browser_back`, `browser_press`)
- Target URL and task description from user

## Tools Reference

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Go to a URL, initializes session |
| `browser_snapshot` | Get DOM/accessibility tree, interactive elements with refs |
| `browser_click` | Click element by ref (`@eN`) |
| `browser_type` | Type into input field by ref |

**React Controlled Components**: `browser_type` does NOT trigger React's onChange event — it only sets the DOM value but React state stays empty. For React textareas/inputs, use browser_console with JavaScript:
```javascript
const textarea = document.querySelector('textarea[placeholder*="..."]');
const nativeSetter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
nativeSetter.call(textarea, 'your text');
textarea.dispatchEvent(new Event('input', { bubbles: true }));
```
Then verify with `textarea.value` and check button `disabled` state to confirm React state updated.

| `browser_scroll` | Scroll up/down |
| `browser_back` | Go back in history |
| `browser_press` | Press keyboard key |
| `browser_vision` | Screenshot + AI analysis; `annotate=true` for element labels |
| `browser_console` | Get JS errors and console output |
| `browser_get_images` | List all images on page with URLs |
| `browser_console(expression)` | Evaluate JS in page context |

## Common Workflows

### 1. Simple Page Read

```
browser_navigate(url="https://example.com")
browser_snapshot()
browser_console(clear=true)  # check for JS errors
```

### 2. Search and Click

```
browser_navigate(url="https://github.com/search?q=trending")
browser_snapshot()  # find search input ref
browser_type(ref="@e3", text="python")
browser_press(key="Enter")
browser_snapshot()  # inspect results
```

### 3. Screenshot with Analysis

```
browser_navigate(url="https://github.com")
browser_vision(question="What is on this page?", annotate=true)
```

### 4. Form Filling and Submission

```
browser_navigate(url="https://github.com/login")
browser_snapshot()  # find username, password fields
browser_type(ref="@e5", text="myuser")
browser_type(ref="@e6", text="mypassword")
browser_click(ref="@e7")  # submit button
```

### 5. Extract Page Content (e.g., GitHub Trending)

```
browser_navigate(url="https://github.com/trending")
browser_snapshot()
browser_vision(question="List the top 10 trending repositories with their names, descriptions, and star counts", annotate=false)
```

### 6. Infinite Scroll Page

```
browser_navigate(url="https://github.com/trending")
for i in range(3):
    browser_scroll(direction="down")
    browser_snapshot()  # check new content loaded
```

## GitHub Trending Workflow

To get GitHub trending projects (as in the example: "recent month, rising fastest top 10"):

```
browser_navigate(url="https://github.com/trending?since=monthly")
browser_snapshot()  # get first page of results
browser_scroll(direction="down")  # load more content (trending is infinite scroll)
browser_scroll(direction="down")
browser_snapshot()  # capture newly loaded content
```

Note: GitHub Trending loads content progressively. For top 10, scroll 2-3 times then extract via `browser_snapshot()` and parse the article elements from the accessibility tree. `browser_vision` can also be used but may need a retry if it returns a screenshot error.

For specific language trending:
```
browser_navigate(url="https://github.com/trending/python?since=monthly")
```

## Content Extraction Pattern

For structured extraction (articles, lists, data):

1. Navigate to page
2. `browser_snapshot()` to understand structure
3. `browser_scroll(direction="down")` repeatedly to load all content
4. `browser_vision(question="Extract all [specific data type] from this page", annotate=false)`
5. Or use `browser_console(expression="...")` for JS-based extraction

## Verification Checklist

After any automated browser task:
- [ ] Page loaded without crash
- [ ] `browser_console()` shows no Error (warnings OK)
- [ ] Expected content visible in snapshot/vision
- [ ] Navigation completed successfully

## Tips

- **Always check `browser_console()`** after navigation — catches JS errors silently
- **Use `annotate=true`** when you need to map visual positions to ref IDs
- **Wait for content** — if page is SPA, give it time to render after navigation
- **Scroll to load more** — infinite scroll pages need explicit scrolling
- **Login handling** — if target site needs auth, use `browser_vision` to see login form, then fill credentials
- **`browser_vision` may return "no screenshot" on first call** — if this happens, call `browser_snapshot()` first, then retry `browser_vision`. This ensures the page context is properly initialized.

## Pitfalls

- Navigation timeout (60s default) — if page is slow, it may timeout; retry
- CSP/WAF blocking — some sites block automated browsers
- Dynamic content — some content loads after initial render; scroll or wait
- Selector instability — refs (`@eN`) can change after page updates; re-snapshot if needed
- **`browser_vision` inconsistency** — can occasionally fail with screenshot access error; always have `browser_snapshot` as fallback for extracting structured content
- **GitHub Trending truncation** — `browser_snapshot` truncates at ~10 repos and scrolling may not load more (lazy loading). Use `browser_console(expression)` with JS instead for reliable structured extraction
- **React controlled components** — `browser_type` does not trigger React's onChange, so React state never updates. Always verify input worked by checking `disabled` state of submit buttons, or use the JS workaround above.

## Reliable Structured Data Extraction (GitHub Trending Example)

When `browser_snapshot` truncates results (e.g., GitHub trending shows only first few items) and `browser_scroll` doesn't trigger lazy loading, use JavaScript injection via `browser_console`:

```javascript
browser_console(expression=`
(function() {
  const articles = document.querySelectorAll('article');
  const results = [];
  articles.forEach((article, i) => {
    const heading = article.querySelector('h2');
    const desc = article.querySelector('p');
    const starsLink = article.querySelector('a[href*="/stargazers"]');
    const forksLink = article.querySelector('a[href*="/forks"]');
    const allText = article.innerText;
    let periodMatch = allText.match(/([\\d,]+)\\s+stars?\\s+(this\\s+week|today|this\\s+month)/i);
    if (heading && i < 10) {
      results.push({
        name: heading.textContent.replace(/\\n/g, ' ').replace(/\\s+/g, ' ').trim(),
        description: desc ? desc.textContent.trim() : '',
        totalStars: starsLink ? starsLink.textContent.replace(/[^\\d,]/g, '').trim() : '',
        forks: forksLink ? forksLink.textContent.replace(/[^\\d,]/g, '').trim() : '',
        period: periodMatch ? periodMatch[0] : ''
      });
    }
  });
  return JSON.stringify(results, null, 2);
})()
`)
```

This extracts: repo name, description, total stars, forks, and stars this period — far more reliable than snapshot truncation for list-based pages.
