-- handle_new_user() is only meant to run as the on_auth_user_created trigger;
-- stop exposing it as an RPC endpoint (/rest/v1/rpc/handle_new_user).
revoke execute on function public.handle_new_user() from public, anon, authenticated;
