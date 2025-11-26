-- Add an 'email' column to the 'licenses' table
ALTER TABLE public.licenses
ADD COLUMN email TEXT;
