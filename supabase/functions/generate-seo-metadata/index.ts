import "jsr:@supabase/functions-js/edge-runtime.d.ts";

interface MetaTags {
  title: string;
  description: string;
  image: string;
  canonicalUrl: string;
  isLive: boolean;
  listenerCount: number;
}

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const diwanId = url.searchParams.get("diwan_id");

  if (!diwanId) {
    return htmlResponse(defaultMeta());
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/diwans` +
        `?id=eq.${diwanId}` +
        `&select=id,title,description,cover_url,is_live,listener_count`,
      {
        headers: {
          apikey: serviceKey,
          Authorization: `Bearer ${serviceKey}`,
        },
      }
    );

    if (!res.ok) return htmlResponse(defaultMeta());

    const diwans: Array<{
      id: string;
      title: string;
      description?: string;
      cover_url?: string;
      is_live?: boolean;
      listener_count?: number;
    }> = await res.json();

    if (!diwans.length) return htmlResponse(defaultMeta());

    const d = diwans[0];
    const isLive = d.is_live === true;
    const listenerCount = d.listener_count ?? 0;
    const canonicalUrl = `https://bayan.app/diwan/${diwanId}`;

    const title = isLive
      ? `🔴 مباشر الآن — ${d.title} | بيان`
      : `${d.title} | بيان`;

    const description =
      d.description ||
      (isLive
        ? `${listenerCount} مستمع الآن — انضم للحوار على بيان!`
        : "اكتشف أفضل المحتوى الصوتي العربي على منصة بيان.");

    const image = d.cover_url || "https://bayan.app/og-default.png";

    return htmlResponse({
      title,
      description,
      image,
      canonicalUrl,
      isLive,
      listenerCount,
    });
  } catch {
    return htmlResponse(defaultMeta());
  }
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function defaultMeta(): MetaTags {
  return {
    title: "بيان — منصة المحتوى العربي المتميز",
    description:
      "انضم إلى أفضل منصة للمحتوى الصوتي العربي. ديوان حي أو مسجل.",
    image: "https://bayan.app/og-default.png",
    canonicalUrl: "https://bayan.app",
    isLive: false,
    listenerCount: 0,
  };
}

function escHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function htmlResponse(meta: MetaTags): Response {
  const liveExtra = meta.isLive
    ? `
  <meta name="bayan:live" content="true" />
  <meta name="bayan:listener_count" content="${meta.listenerCount}" />
  <meta property="og:video:type" content="application/x-mpegURL" />`
    : "";

  const html = `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />

  <!-- Primary Meta -->
  <title>${escHtml(meta.title)}</title>
  <meta name="description" content="${escHtml(meta.description)}" />
  <link rel="canonical" href="${escHtml(meta.canonicalUrl)}" />

  <!-- Open Graph (Facebook, WhatsApp, iMessage) -->
  <meta property="og:type"        content="website" />
  <meta property="og:site_name"   content="بيان" />
  <meta property="og:url"         content="${escHtml(meta.canonicalUrl)}" />
  <meta property="og:title"       content="${escHtml(meta.title)}" />
  <meta property="og:description" content="${escHtml(meta.description)}" />
  <meta property="og:image"       content="${escHtml(meta.image)}" />
  <meta property="og:image:secure_url" content="${escHtml(meta.image)}" />
  <meta property="og:image:width"  content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:locale"      content="ar_AR" />${liveExtra}

  <!-- Twitter / X Card -->
  <meta name="twitter:card"        content="summary_large_image" />
  <meta name="twitter:site"        content="@bayanapp" />
  <meta name="twitter:title"       content="${escHtml(meta.title)}" />
  <meta name="twitter:description" content="${escHtml(meta.description)}" />
  <meta name="twitter:image"       content="${escHtml(meta.image)}" />

  <!-- Schema.org JSON-LD -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Event",
    "name": "${escHtml(meta.title)}",
    "description": "${escHtml(meta.description)}",
    "image": "${escHtml(meta.image)}",
    "url": "${escHtml(meta.canonicalUrl)}",
    "eventStatus": "${meta.isLive ? "https://schema.org/EventScheduled" : "https://schema.org/EventPostponed"}",
    "organizer": { "@type": "Organization", "name": "بيان" }
  }
  </script>
</head>
<body>
  <script>window.location.replace("${escHtml(meta.canonicalUrl)}");</script>
  <noscript><a href="${escHtml(meta.canonicalUrl)}">افتح في بيان</a></noscript>
</body>
</html>`;

  return new Response(html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": meta.isLive
        ? "public, max-age=10, stale-while-revalidate=30"
        : "public, max-age=300, stale-while-revalidate=600",
    },
  });
}
