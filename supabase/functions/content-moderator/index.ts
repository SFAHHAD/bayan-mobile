import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Policy categories checked by GPT-4o-mini
const SYSTEM_PROMPT = `You are a content moderation assistant for Bayan, an Arabic audio platform.
Analyse the provided Diwan title and description for policy violations.

Return ONLY valid JSON in this exact schema:
{
  "verdict": "approved" | "flagged" | "blocked",
  "categories": string[],   // violated categories, empty if approved
  "reason": string,         // brief Arabic or English explanation
  "confidence": number      // 0.000 – 1.000
}

Violation categories to detect:
- hate_speech
- harassment
- sexual_content
- violence
- misinformation
- spam
- illegal_content
- extremism

Rules:
- "approved"  → no violations detected
- "flagged"   → minor / ambiguous violation that needs human review
- "blocked"   → clear, severe violation; content must not go live`;

interface ModerationPayload {
  diwan_id: string;
  title: string;
  description?: string;
}

interface ModerationResult {
  verdict: "approved" | "flagged" | "blocked";
  categories: string[];
  reason: string;
  confidence: number;
}

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const payload: ModerationPayload = await req.json();
  const { diwan_id, title, description } = payload;

  if (!diwan_id || !title) {
    return new Response(
      JSON.stringify({ error: "diwan_id and title are required" }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const openaiKey = Deno.env.get("OPENAI_API_KEY");
  if (!openaiKey) {
    return new Response(JSON.stringify({ error: "OpenAI key not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Build user message
  const userMessage = [
    `Title: ${title}`,
    description ? `Description: ${description}` : "",
  ]
    .filter(Boolean)
    .join("\n");

  // Call GPT-4o-mini
  const openaiResponse = await fetch(
    "https://api.openai.com/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        temperature: 0,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: userMessage },
        ],
      }),
    },
  );

  if (!openaiResponse.ok) {
    const errText = await openaiResponse.text();
    console.error("OpenAI error:", errText);
    return new Response(
      JSON.stringify({ error: "AI moderation service unavailable" }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }

  const openaiJson = await openaiResponse.json();
  let result: ModerationResult;

  try {
    result = JSON.parse(
      openaiJson.choices[0].message.content,
    ) as ModerationResult;
  } catch {
    result = {
      verdict: "flagged",
      categories: [],
      reason: "Failed to parse AI response — queued for manual review",
      confidence: 0,
    };
  }

  // Persist to moderation log
  await supabase.from("content_moderation_log").insert({
    diwan_id,
    content_type: "diwan_metadata",
    verdict: result.verdict,
    categories: result.categories,
    confidence: result.confidence,
    raw_response: openaiJson,
  });

  // Update diwan moderation_status
  const dbStatus =
    result.verdict === "approved"
      ? "approved"
      : result.verdict === "blocked"
        ? "rejected"
        : "pending"; // flagged → stays pending for human review

  await supabase
    .from("diwans")
    .update({ moderation_status: dbStatus })
    .eq("id", diwan_id);

  return new Response(
    JSON.stringify({
      diwan_id,
      verdict: result.verdict,
      categories: result.categories,
      reason: result.reason,
      confidence: result.confidence,
      moderation_status: dbStatus,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
