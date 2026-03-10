CREATE TABLE IF NOT EXISTS log_entries (
  ID                  serial                        PRIMARY KEY,
  time_of_creation    timestamp with time zone      NOT NULL,
  json                text                          NOT NULL,
  solved              boolean                       NOT NULL DEFAULT false
);
COMMENT ON TABLE log_entries IS 'Table containing all relevant error log entries.';
