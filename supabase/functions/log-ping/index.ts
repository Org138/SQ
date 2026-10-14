// Writes one line to the project's Edge Function logs and returns.
import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

// Requires the project's publishable or secret key in the `apikey` header.
export default {
  fetch: withSupabase({ auth: ["publishable", "secret"] }, () => {
    console.log("log-ping: called");
    return Response.json({ ok: true });
  }),
};

/* To invoke locally, use the publishable key printed by `supabase status`:

  curl -i -X POST 'http://127.0.0.1:54321/functions/v1/log-ping' \
    --header 'apikey: <publishable key>'

*/
