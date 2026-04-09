import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// auto-archive-diwans
// Scheduled Edge Function — invoke via Supabase cron (pg_cron) every 15 min.
// Example cron registration (run in Supabase SQL editor):
//
//   select cron.schedule(
//     'auto-archive-diwans', '*/15 * * * *',
//     'select net.http_post(url:=''<project-url>/functions/v1/auto-archive-diwans'',body:=''{}''::jsonb)'
//   );
Deno.serve(async (req: Request) => {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    serviceKey
  );

  const { data, error } = await supabase.rpc("auto_archive_inactive_diwans");

  if (error) {
    console.error("auto-archive error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  console.log(`Archived ${data} inactive diwans`);
  return new Response(
    JSON.stringify({ archived_count: data }),
    { headers: { "Content-Type": "application/json" } }
  );
});
