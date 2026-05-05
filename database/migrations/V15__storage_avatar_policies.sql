-- Create avatars bucket (idempotent)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Drop existing policies to make migration re-runnable
drop policy if exists "Users can upload their own avatar" on storage.objects;
drop policy if exists "Users can update their own avatar" on storage.objects;
drop policy if exists "Users can delete their own avatar" on storage.objects;
drop policy if exists "Public avatar read" on storage.objects;

-- Upload: authenticated users can only upload inside their own folder
create policy "Users can upload their own avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- Update (upsert)
create policy "Users can update their own avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- Delete old avatar before uploading new one
create policy "Users can delete their own avatar"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[2] = auth.uid()::text
);

-- Public read so avatars are visible without auth
create policy "Public avatar read"
on storage.objects
for select
to public
using (bucket_id = 'avatars');
