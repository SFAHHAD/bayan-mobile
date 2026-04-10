import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { AccessToken } from "npm:livekit-server-sdk@2";

// get-livekit-token
// Returns a signed LiveKit token whose publish/subscribe permissions
// reflect the caller's role in diwan_participants.
//
// Required Supabase Edge Function secrets:
//   LIVEKIT_URL        — e.g. wss://your-project.livekit.cloud
//   LIVEKIT_API_KEY    — from LiveKit dashboard
//   LIVEKIT_API_SECRET — from LiveKit dashboard

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: authHeader } } }
  );

  // Verify the requesting user
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { diwan_id } = await req.json();
  if (!diwan_id) {
    return new Response(JSON.stringify({ error: "diwan_id is required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Fetch the user's role via RLS-protected query
  const { data: participant } = await supabase
    .from("diwan_participants")
    .select("role")
    .eq("diwan_id", diwan_id)
    .eq("user_id", user.id)
    .maybeSingle();

  const role: string = participant?.role ?? "listener";
  const canPublish = role === "host" || role === "speaker";
  const isAdmin = role === "host";

  // Fetch user display name
  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name")
    .eq("id", user.id)
    .maybeSingle();

  const displayName: string = profile?.display_name ?? user.id;

  // Build LiveKit token
  const apiKey = Deno.env.get("LIVEKIT_API_KEY") ?? "";
  const apiSecret = Deno.env.get("LIVEKIT_API_SECRET") ?? "";

  const at = new AccessToken(apiKey, apiSecret, {
    identity: user.id,
    name: displayName,
    ttl: "4h",
  });

  at.addGrant({
    roomJoin: true,
    room: diwan_id,
    canPublish,
    canSubscribe: true,
    canPublishData: canPublish,
    roomAdmin: isAdmin,
  });

  const token = await at.toJwt();

  return new Response(
    JSON.stringify({
      token,
      livekit_url: Deno.env.get("LIVEKIT_URL"),
      role,
    }),
    { headers: { "Content-Type": "application/json" } }
  );
});
