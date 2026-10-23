#!/usr/bin/env bash
# Two sessions link A -> B and B -> A at the same moment. The second must wait
# for the first to commit and then be refused as a cycle (see the
# combine_task_dependency_checks migration). pgTAP runs in one session, so
# this needs two real connections. Run against the local stack:
#
#   supabase/tests/concurrency/dependency_cycle_race.sh
#
# DB_URL overrides the database; PSQL overrides the psql command.
set -euo pipefail

DB_URL=${DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}
PSQL=${PSQL:-psql}

user=33333333-3333-3333-3333-333333333333
a=cccccccc-0000-0000-0000-000000000001
b=cccccccc-0000-0000-0000-000000000002
out=$(mktemp -d)

q() { $PSQL "$DB_URL" -X -q -t -A -v ON_ERROR_STOP=1 "$@"; }

# Deleting the user cascades to the profile, tasks and links.
delete_user() { q -c "delete from auth.users where id = '$user'" >/dev/null || true; }
trap 'delete_user; rm -rf "$out"' EXIT
delete_user

fail() { echo "FAIL: $1" >&2; exit 1; }

# Waits up to 10s for a query to return t.
wait_for() {
  for _ in $(seq 100); do
    [ "$(q -c "$1")" = t ] && return 0
    sleep 0.1
  done
  return 1
}

q <<SQL
insert into auth.users (id, email) values ('$user', 'race@example.com');
insert into public.tasks (id, owner_id, title) values
  ('$a', '$user', 'A'),
  ('$b', '$user', 'B');
SQL

# Session 1: link A -> B, then hold the transaction open for a few seconds.
q > "$out/1.log" 2>&1 <<SQL &
set application_name = 'cycle_race_1';
begin;
insert into public.task_dependencies (task_id, depends_on_task_id) values ('$a', '$b');
select pg_sleep(5);
commit;
SQL
s1=$!

wait_for "select exists (select 1 from pg_stat_activity
          where application_name = 'cycle_race_1' and wait_event = 'PgSleep')" ||
  fail "session 1 never reached its open transaction"

# Session 2: link B -> A while session 1 hasn't committed.
q > "$out/2.log" 2>&1 <<SQL &
set application_name = 'cycle_race_2';
insert into public.task_dependencies (task_id, depends_on_task_id) values ('$b', '$a');
SQL
s2=$!

wait_for "select exists (select 1 from pg_stat_activity
          where application_name = 'cycle_race_2'
            and wait_event_type = 'Lock' and wait_event = 'advisory')" ||
  fail "session 2 didn't wait for session 1's lock"
echo "ok: session 2 waits for session 1"

wait "$s1" || fail "session 1 failed: $(cat "$out/1.log")"
if wait "$s2"; then
  fail "session 2 linked B -> A, creating a cycle"
fi
grep -q 'Dependency would create a cycle' "$out/2.log" ||
  fail "session 2 failed for another reason: $(cat "$out/2.log")"
echo "ok: session 2 is refused as a cycle"

[ "$(q -c "select count(*) from public.task_dependencies where task_id in ('$a', '$b')")" = 1 ] ||
  fail "expected exactly one link"
echo "ok: only A -> B was saved"
