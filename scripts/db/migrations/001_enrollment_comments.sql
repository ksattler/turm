ALTER TABLE enrolled ADD COLUMN IF NOT EXISTS comment varchar(511);
ALTER TABLE events ADD COLUMN IF NOT EXISTS has_comments boolean NOT NULL DEFAULT false;
