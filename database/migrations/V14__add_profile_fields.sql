-- V14: Add extended profile fields
-- Adds personal, professional and verification columns to the profiles table.

alter table profiles
  add column if not exists phone          text,
  add column if not exists cpf            text,
  add column if not exists job_title      text,
  add column if not exists company        text,
  add column if not exists email_verified boolean default false not null,
  add column if not exists phone_verified boolean default false not null;
