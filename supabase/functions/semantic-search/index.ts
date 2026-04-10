import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const EMBEDDING_MODEL = "text-embedding-3-small";

interface SearchBody {
  query: string;
  limit?: number;
  threshold?: number;
  type?: "diwan" | "voice";
}

async function embedText(text: string): Promise<number[]> {
  const resp = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ model: EMBEDDING_MODEL, input: text }),
  });
  if (!resp.ok) throw new Error(`OpenAI ${resp.status}: ${await resp.text()}`);
  const json = await resp.json();
  return json.data[0].embedding as number[];
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: SearchBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const {
    query,
    limit = 10,
    threshold = 0.7,
    type = "diwan",
  } = body;

  if (!query || query.trim().length === 0) {
    return new Response(JSON.stringify({ error: "query must not be empty" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Generate embedding for the user's query
  let queryEmbedding: number[];
  try {
    queryEmbedding = await embedText(query.trim());
  } catch (err) {
    return new Response(
      JSON.stringify({ error: `Embedding failed: ${err}` }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  // Use the caller's JWT so RLS policies apply correctly
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const rpcName = type === "voice" ? "match_voices" : "match_diwans";

  const { data, error } = await supabase.rpc(rpcName, {
    query_embedding: `[${queryEmbedding.join(",")}]`,
    match_threshold: threshold,
    match_count: Math.min(limit, 50),
  });

  if (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  return new Response(
    JSON.stringify({ results: data ?? [], query }),
    { headers: { "Content-Type": "application/json" } }
  );
});
