import "jsr:@supabase/functions-js/edge-runtime.d.ts";

interface SecretStatus {
  key: string;
  isSet: boolean;
  maskedHint: string | null;
}

interface HealthReport {
  allSecretsConfigured: boolean;
  secrets: SecretStatus[];
  checkedAt: string;
  environment: string;
}

const REQUIRED_SECRETS = [
  "OPENAI_API_KEY",
  "LIVEKIT_API_KEY",
  "LIVEKIT_API_SECRET",
  "FCM_SERVER_KEY",
  "SUPABASE_SERVICE_ROLE_KEY",
] as const;

Deno.serve(async (req: Request) => {
  // Only callable by service_role or internal cron
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!authHeader.includes(serviceKey) && serviceKey !== "") {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const secrets: SecretStatus[] = REQUIRED_SECRETS.map((key) => {
    const value = Deno.env.get(key);
    const isSet = Boolean(value && value.trim().length > 0);
    const maskedHint = isSet && value
      ? `${value.slice(0, 4)}${"*".repeat(Math.min(value.length - 4, 20))}`
      : null;
    return { key, isSet, maskedHint };
  });

  const allSecretsConfigured = secrets.every((s) => s.isSet);
  const environment = Deno.env.get("ENVIRONMENT") ?? "production";

  const report: HealthReport = {
    allSecretsConfigured,
    secrets,
    checkedAt: new Date().toISOString(),
    environment,
  };

  // Persist health check results to DB
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  try {
    await Promise.all(
      secrets.map((s) =>
        fetch(`${supabaseUrl}/rest/v1/rpc/upsert_production_health`, {
          method: "POST",
          headers: {
            apikey: serviceKey,
            Authorization: `Bearer ${serviceKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            p_key: s.key,
            p_is_set: s.isSet,
            p_masked_hint: s.maskedHint,
          }),
        })
      )
    );
  } catch {
    // Non-fatal: continue even if DB write fails
  }

  return new Response(JSON.stringify(report), {
    status: allSecretsConfigured ? 200 : 206,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
});
