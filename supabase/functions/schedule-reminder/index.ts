import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const WINDOW_START_MS = 15 * 60 * 1000; // 15 min ahead
const WINDOW_END_MS = 16 * 60 * 1000; // 16 min ahead

Deno.serve(async (_req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const now = new Date();
  const windowStart = new Date(now.getTime() + WINDOW_START_MS).toISOString();
  const windowEnd = new Date(now.getTime() + WINDOW_END_MS).toISOString();

  // Find upcoming diwans in the 15-min reminder window
  const { data: scheduled, error } = await supabase
    .from("scheduled_diwans")
    .select("id, diwan_id, host_id, start_time, diwans(title)")
    .gte("start_time", windowStart)
    .lte("start_time", windowEnd)
    .eq("reminder_sent", false)
    .eq("is_cancelled", false);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  let notificationsSent = 0;

  for (const item of scheduled ?? []) {
    const diwan = item as any;

    // Followers of the host
    const { data: follows } = await supabase
      .from("follows")
      .select("follower_id")
      .eq("following_id", diwan.host_id);

    const followerIds = (follows ?? []).map((f: any) => f.follower_id);

    if (followerIds.length > 0) {
      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token, platform, user_id")
        .in("user_id", followerIds);

      const pushUrl = Deno.env.get("PUSH_NOTIFICATION_URL");
      const pushKey = Deno.env.get("PUSH_NOTIFICATION_KEY");

      if (pushUrl && pushKey && tokens && tokens.length > 0) {
        const messages = tokens.map((t: any) => ({
          to: t.token,
          title: "ديوانية قادمة",
          body: `${diwan.diwans?.title ?? "ديوانية"} تبدأ خلال ١٥ دقيقة`,
          data: { type: "scheduled_reminder", diwan_id: diwan.diwan_id },
        }));

        await fetch(pushUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${pushKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ messages }),
        });

        notificationsSent += tokens.length;
      }
    }

    // Mark reminder as sent regardless (prevents duplicate runs)
    await supabase
      .from("scheduled_diwans")
      .update({ reminder_sent: true })
      .eq("id", diwan.id);
  }

  return new Response(
    JSON.stringify({
      processed: scheduled?.length ?? 0,
      notifications_sent: notificationsSent,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
