import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const EMBEDDING_MODEL = "text-embedding-3-small";
const EMBEDDING_DIM = 1536;

type ContentType = "diwan" | "voice";

interface RequestBody {
  type: ContentType;
  id: string;
}

async function generateEmbedding(text: string): Promise<number[]> {
  const resp = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ model: EMBEDDING_MODEL, input: text }),
  });
  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`OpenAI error ${resp.status}: ${err}`);
  }
  const json = await resp.json();
  return json.data[0].embedding as number[];
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { type, id } = body;
  if (!type || !id) {
    return new Response(
      JSON.stringify({ error: "Missing required fields: type, id" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  // Service-role client — bypasses RLS for reading/writing embeddings
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  let text = "";
  if (type === "diwan") {
    const { data, error } = await supabase
      .from("diwans")
      .select("title, description")
      .eq("id", id)
      .single();
    if (error || !data) {
      return new Response(JSON.stringify({ error: "Diwan not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }
    text = [data.title, data.description].filter(Boolean).join(" ").trim();
  } else if (type === "voice") {
    const { data, error } = await supabase
      .from("voice_clips")
      .select("title, description")
      .eq("id", id)
      .single();
    if (error || !data) {
      return new Response(JSON.stringify({ error: "Voice clip not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }
    text = [data.title, data.description].filter(Boolean).join(" ").trim();
  } else {
    return new Response(
      JSON.stringify({ error: "type must be diwan or voice" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  if (!text) {
    return new Response(
      JSON.stringify({ error: "No text content to embed" }),
      { status: 422, headers: { "Content-Type": "application/json" } }
    );
  }

  let embedding: number[];
  try {
    embedding = await generateEmbedding(text);
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Embedding generation failed: ${err}` }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  const table = type === "diwan" ? "diwans" : "voice_clips";
  const { error: updateError } = await supabase
    .from(table)
    .update({ embedding: `[${embedding.join(",")}]` })
    .eq("id", id);

  if (updateError) {
    return new Response(
      JSON.stringify({ error: `DB update failed: ${updateError.message}` }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({ success: true, dimension: EMBEDDING_DIM }),
    { headers: { "Content-Type": "application/json" } }
  );
});
