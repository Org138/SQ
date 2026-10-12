-- The avatars bucket is public, so anything uploaded to it is served from the
-- project's domain. Accept only raster images: an SVG (or HTML) upload served
-- with its own content type can run script in the viewer's browser.
-- Storage rejects uploads whose declared content type or size falls outside
-- these limits, before the insert policy runs.
update storage.buckets
set
  file_size_limit = 1048576, -- 1 MiB; the app resizes avatars to 300x300
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'avatars';

-- Also require a matching file extension, so a file can't claim image/png
-- while being named .svg or .html.
drop policy "Users can upload avatars to their own folder" on storage.objects;

create policy "Users can upload avatars to their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'webp')
  );
