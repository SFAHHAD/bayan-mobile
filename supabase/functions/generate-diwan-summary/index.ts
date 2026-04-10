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

  let body: { diwan_id?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { diwan_id } = body;
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

  // Mark as processing
  await supabase
    .from("diwan_summaries")
    .upsert({ diwan_id, status: "processing" }, { onConflict: "diwan_id" });

  try {
    // Fetch voice clips for this diwan
    const { data: clips } = await supabase
      .from("voices")
      .select("title, public_url, duration_seconds")
      .eq("diwan_id", diwan_id)
      .order("created_at");

    if (!clips || clips.length === 0) {
      await supabase.from("diwan_summaries").upsert(
        {
          diwan_id,
          status: "done",
          summary: "لا توجد مقاطع صوتية لهذه الجلسة.",
          key_points: [],
          generated_at: new Date().toISOString(),
        },
        { onConflict: "diwan_id" },
      );
      return new Response(
        JSON.stringify({ summary: "No voice clips found." }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      throw new Error("OPENAI_API_KEY not configured in project secrets");
    }

    // Build structured prompt from clip metadata
    const clipList = (clips as any[])
      .map((c, i) => `${i + 1}. ${c.title} (${c.duration_seconds}s)`)
      .join("\n");

    const prompt =
      `أنت مساعد ذكاء اصطناعي متخصص في تلخيص جلسات النقاش العربية.\n\n` +
      `بناءً على عناوين المقاطع الصوتية التالية من جلسة ديوانية:\n${clipList}\n\n` +
      `أنشئ:\n` +
      `1. ملخصاً موجزاً للجلسة (فقرة واحدة بالعربية الفصحى)\n` +
      `2. قائمة JSON بأبرز النقاط (3-5 نقاط، مصفوفة نصية)\n\n` +
      `الردّ يجب أن يكون JSON بالشكل:\n` +
      `{"summary":"...","key_points":["...","..."]}`;

    const gptRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 600,
        temperature: 0.6,
        response_format: { type: "json_object" },
      }),
    });

    const gptData = await gptRes.json();
    const raw = gptData.choices?.[0]?.message?.content ?? "{}";

    let parsed: { summary?: string; key_points?: string[] } = {};
    try {
      parsed = JSON.parse(raw);
    } catch {
      parsed = { summary: raw, key_points: [] };
    }

    const summary = parsed.summary ?? "تعذّر إنشاء الملخص.";
    const keyPoints = parsed.key_points ?? [];

    await supabase.from("diwan_summaries").upsert(
      {
        diwan_id,
        summary,
        key_points: keyPoints,
        status: "done",
        generated_at: new Date().toISOString(),
      },
      { onConflict: "diwan_id" },
    );

    return new Response(JSON.stringify({ summary, key_points: keyPoints }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";

    await supabase
      .from("diwan_summaries")
      .upsert(
        { diwan_id, status: "failed" },
        { onConflict: "diwan_id" },
      );

    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
