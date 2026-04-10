import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
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

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify caller is the host
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

  // Fetch diwan
  const { data: diwan, error: diwanErr } = await supabase
    .from("diwans")
    .select("id, title, owner_id, created_at, updated_at")
    .eq("id", diwan_id)
    .single();

  if (diwanErr || !diwan) {
    return new Response(JSON.stringify({ error: "Diwan not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (diwan.owner_id !== user.id) {
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ---- Aggregate metrics ------------------------------------------------

  // 1. Total duration: difference between created_at and last update where is_live → false
  const createdAt = new Date(diwan.created_at);
  const endedAt = new Date(diwan.updated_at);
  const totalDurationSeconds = Math.max(
    0,
    Math.floor((endedAt.getTime() - createdAt.getTime()) / 1000),
  );

  // 2. Peak listeners + unique listeners from analytics snapshot
  const { data: analytics } = await supabase
    .from("diwan_analytics")
    .select("peak_listeners, unique_listeners")
    .eq("diwan_id", diwan_id)
    .maybeSingle();

  const peakListeners: number = analytics?.peak_listeners ?? 0;
  const uniqueListeners: number = analytics?.unique_listeners ?? 0;

  // 3. Total gifts value: sum wallet_transactions of type 'bonus' referencing this diwan
  const { data: giftRows } = await supabase
    .from("wallet_transactions")
    .select("amount")
    .eq("ref_diwan_id", diwan_id)
    .eq("type", "bonus");

  const totalGiftsValue: number = (giftRows ?? []).reduce(
    (sum: number, r: { amount: number }) => sum + Math.max(0, r.amount),
    0,
  );

  // 4. Sentiment summary from diwan_summaries (v1.1)
  const { data: summaryRow } = await supabase
    .from("diwan_summaries")
    .select("summary, key_points, status")
    .eq("diwan_id", diwan_id)
    .maybeSingle();

  const sentimentSummary: string =
    summaryRow?.status === "done" ? summaryRow.summary ?? "" : "";
  const keyPoints: string[] = summaryRow?.key_points ?? [];

  // 5. Tickets sold + revenue
  const { data: ticketRows } = await supabase
    .from("tickets")
    .select("purchase_price")
    .eq("diwan_id", diwan_id);

  const ticketsSold: number = ticketRows?.length ?? 0;
  const ticketRevenue: number = (ticketRows ?? []).reduce(
    (sum: number, r: { purchase_price: number }) => sum + r.purchase_price,
    0,
  );

  // 6. Poll engagement
  const { data: polls } = await supabase
    .from("polls")
    .select("id, total_votes, status")
    .eq("diwan_id", diwan_id);

  const totalPollVotes: number = (polls ?? []).reduce(
    (sum: number, p: { total_votes: number }) => sum + (p.total_votes ?? 0),
    0,
  );

  // 7. Q&A engagement
  const { data: questions } = await supabase
    .from("questions")
    .select("id, upvotes_count, is_answered")
    .eq("diwan_id", diwan_id)
    .eq("is_hidden", false);

  const totalQuestions: number = questions?.length ?? 0;
  const answeredQuestions: number = (questions ?? []).filter(
    (q: { is_answered: boolean }) => q.is_answered,
  ).length;

  // ---- Build report -------------------------------------------------------
  const report = {
    diwan_id,
    title: diwan.title,
    generated_at: new Date().toISOString(),
    session: {
      total_duration_seconds: totalDurationSeconds,
      total_duration_formatted: formatDuration(totalDurationSeconds),
      started_at: diwan.created_at,
      ended_at: diwan.updated_at,
    },
    audience: {
      peak_listeners: peakListeners,
      unique_listeners: uniqueListeners,
    },
    economy: {
      total_gifts_value: totalGiftsValue,
      tickets_sold: ticketsSold,
      ticket_revenue: ticketRevenue,
      total_revenue: totalGiftsValue + ticketRevenue,
    },
    engagement: {
      total_poll_votes: totalPollVotes,
      polls_conducted: (polls ?? []).length,
      total_questions: totalQuestions,
      questions_answered: answeredQuestions,
    },
    ai_insights: {
      summary: sentimentSummary,
      key_points: keyPoints,
    },
  };

  // Persist report timestamp to analytics snapshot
  await supabase
    .from("diwan_analytics")
    .upsert(
      {
        diwan_id,
        total_duration_seconds: totalDurationSeconds,
        peak_listeners: peakListeners,
        unique_listeners: uniqueListeners,
        total_gifts_value: totalGiftsValue,
        report_generated_at: report.generated_at,
      },
      { onConflict: "diwan_id" },
    );

  return new Response(JSON.stringify(report), {
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
});

function formatDuration(totalSeconds: number): string {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  const hStr = h > 0 ? `${h}h ` : "";
  const mStr = m > 0 ? `${m}m ` : "";
  const sStr = `${s}s`;
  return `${hStr}${mStr}${sStr}`.trim() || "0s";
}
