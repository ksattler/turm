DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'blacklists' AND table_schema = 'public') THEN
    ALTER TABLE blacklists RENAME TO blocklists;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whitelists' AND table_schema = 'public') THEN
    ALTER TABLE whitelists RENAME TO allowlists;
  END IF;
END $$;
