import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS });
  }

  try {
    const { voice_clip_id } = await req.json();

    if (!voice_clip_id) {
      return json({ error: "voice_clip_id required" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const openaiKey = Deno.env.get("OPENAI_API_KEY")!;

    const authHeaders = {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
    };

    // -------------------------------------------------------------------------
    // 1. Fetch the clip record (voices table)
    // -------------------------------------------------------------------------
    const clipRes = await fetch(
      `${supabaseUrl}/rest/v1/voices?id=eq.${voice_clip_id}` +
        `&select=id,public_url,storage_path,transcription_status`,
      { headers: authHeaders }
    );
    const clips: Array<{
      id: string;
      public_url: string | null;
      storage_path: string;
      transcription_status: string;
    }> = await clipRes.json();

    if (!clips.length) {
      return json({ error: "clip_not_found" }, 404);
    }

    const clip = clips[0];

    if (clip.transcription_status === "completed") {
      return json({ status: "already_transcribed" });
    }

    // -------------------------------------------------------------------------
    // 2. Mark as processing to prevent duplicate jobs
    // -------------------------------------------------------------------------
    await patch(supabaseUrl, serviceKey, voice_clip_id, {
      transcription_status: "processing",
    });

    // -------------------------------------------------------------------------
    // 3. Resolve audio URL — prefer public_url, fallback to signed Storage URL
    // -------------------------------------------------------------------------
    let audioUrl = clip.public_url;
    if (!audioUrl) {
      const signedRes = await fetch(
        `${supabaseUrl}/storage/v1/object/sign/voice_clips/${clip.storage_path}`,
        {
          method: "POST",
          headers: { ...authHeaders, "Content-Type": "application/json" },
          body: JSON.stringify({ expiresIn: 300 }),
        }
      );
      const { signedURL } = await signedRes.json();
      audioUrl = `${supabaseUrl}/storage/v1${signedURL}`;
    }

    // -------------------------------------------------------------------------
    // 4. Download audio bytes
    // -------------------------------------------------------------------------
    const audioRes = await fetch(audioUrl!);
    if (!audioRes.ok) {
      await markFailed(supabaseUrl, serviceKey, voice_clip_id);
      return json({ error: `audio_fetch_failed: ${audioRes.status}` }, 502);
    }
    const audioBytes = await audioRes.arrayBuffer();

    // -------------------------------------------------------------------------
    // 5. Call OpenAI Whisper
    // -------------------------------------------------------------------------
    const form = new FormData();
    form.append(
      "file",
      new Blob([audioBytes], { type: "audio/m4a" }),
      "audio.m4a"
    );
    form.append("model", "whisper-1");
    form.append("language", "ar");
    form.append("response_format", "json");

    const whisperRes = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${openaiKey}` },
        body: form,
      }
    );

    if (!whisperRes.ok) {
      const errText = await whisperRes.text();
      await markFailed(supabaseUrl, serviceKey, voice_clip_id);
      return json({ error: `whisper_error: ${errText}` }, 502);
    }

    const { text: transcriptText } = await whisperRes.json();

    // -------------------------------------------------------------------------
    // 6. Store transcript
    // -------------------------------------------------------------------------
    await patch(supabaseUrl, serviceKey, voice_clip_id, {
      transcript_text: transcriptText,
      transcription_status: "completed",
    });

    return json({ success: true, transcript: transcriptText });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

async function patch(
  supabaseUrl: string,
  serviceKey: string,
  clipId: string,
  payload: Record<string, unknown>
): Promise<void> {
  await fetch(`${supabaseUrl}/rest/v1/voices?id=eq.${clipId}`, {
    method: "PATCH",
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(payload),
  });
}

async function markFailed(
  supabaseUrl: string,
  serviceKey: string,
  clipId: string
): Promise<void> {
  await patch(supabaseUrl, serviceKey, clipId, {
    transcription_status: "failed",
  });
}
