import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import QRCode from "npm:qrcode";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Identify caller
  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const {
    data: { user },
    error: authError,
  } = await anonClient.auth.getUser();

  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Invalid token" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Fetch display name
  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name")
    .eq("id", user.id)
    .single();

  const displayName: string = profile?.display_name ?? "Bayan User";

  // Get or create referral code
  const { data: codeData } = await supabase.rpc(
    "get_or_create_referral_code",
    {},
    // Call as the authenticated user by signing with anon client
  );

  // Fallback: query directly
  let referralCode: string = codeData ?? "";
  if (!referralCode) {
    const { data: row } = await supabase
      .from("referral_codes")
      .select("code")
      .eq("user_id", user.id)
      .maybeSingle();
    referralCode = row?.code ?? "BAYAN";
  }

  const referralUrl = `https://bayan.app/join?ref=${referralCode}`;

  // Generate QR code as base64 PNG data URL
  const qrDataUrl: string = await QRCode.toDataURL(referralUrl, {
    width: 200,
    margin: 1,
    color: { dark: "#1a1a2e", light: "#f5f0e8" },
  });

  // Build SVG share card (400×500)
  const encodedName = displayName
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="400" height="520" viewBox="0 0 400 520">
  <!-- Background -->
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%"   stop-color="#1a1a2e"/>
      <stop offset="100%" stop-color="#16213e"/>
    </linearGradient>
    <linearGradient id="gold" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%"   stop-color="#c9a227"/>
      <stop offset="100%" stop-color="#e8c96b"/>
    </linearGradient>
  </defs>

  <rect width="400" height="520" rx="20" fill="url(#bg)"/>

  <!-- Gold accent bar -->
  <rect x="0" y="0" width="400" height="6" rx="3" fill="url(#gold)"/>

  <!-- Logo text -->
  <text x="200" y="60" font-family="Georgia, serif" font-size="36"
        fill="url(#gold)" text-anchor="middle" font-weight="bold">بَيان</text>

  <!-- Tagline -->
  <text x="200" y="90" font-family="Arial, sans-serif" font-size="13"
        fill="#a0a0b0" text-anchor="middle">منصة المحتوى العربي الراقي</text>

  <!-- Divider -->
  <line x1="40" y1="108" x2="360" y2="108" stroke="#c9a227" stroke-width="0.5" opacity="0.4"/>

  <!-- Invite copy -->
  <text x="200" y="142" font-family="Arial, sans-serif" font-size="15"
        fill="#e8e8f0" text-anchor="middle">يدعوك</text>
  <text x="200" y="172" font-family="Georgia, serif" font-size="22"
        fill="url(#gold)" text-anchor="middle" font-weight="bold">${encodedName}</text>
  <text x="200" y="200" font-family="Arial, sans-serif" font-size="15"
        fill="#e8e8f0" text-anchor="middle">للانضمام إلى بيان</text>

  <!-- QR code -->
  <image href="${qrDataUrl}" x="100" y="220" width="200" height="200"/>

  <!-- Referral code pill -->
  <rect x="120" y="438" width="160" height="34" rx="17" fill="#c9a227" opacity="0.15"/>
  <text x="200" y="459" font-family="monospace" font-size="16"
        fill="#c9a227" text-anchor="middle" font-weight="bold" letter-spacing="3">${referralCode}</text>

  <!-- Footer -->
  <text x="200" y="506" font-family="Arial, sans-serif" font-size="11"
        fill="#606080" text-anchor="middle">bayan.app/join?ref=${referralCode}</text>
</svg>`;

  // Return JSON (includes SVG string + QR data URL for flexible client rendering)
  // Also expose the raw SVG as a separate endpoint format via Accept header
  const acceptHeader = req.headers.get("Accept") ?? "";
  if (acceptHeader.includes("image/svg+xml")) {
    return new Response(svg, {
      headers: {
        "Content-Type": "image/svg+xml",
        "Cache-Control": "no-store",
      },
    });
  }

  return new Response(
    JSON.stringify({
      svg,
      referral_code: referralCode,
      referral_url: referralUrl,
      qr_data_url: qrDataUrl,
      display_name: displayName,
    }),
    {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
      },
    },
  );
});
