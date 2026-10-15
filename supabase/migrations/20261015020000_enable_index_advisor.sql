-- index_advisor suggests indexes for a query and estimates its cost before
-- and after, using hypothetical indexes from hypopg (nothing is built).
-- Usage: select * from extensions.index_advisor('select ...');
create extension if not exists hypopg with schema extensions;
create extension if not exists index_advisor with schema extensions;
