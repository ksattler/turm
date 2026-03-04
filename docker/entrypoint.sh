#!/bin/sh
set -e

# Write the passwords file that Revel reads on startup.
# DB_PASSWORD is required; EMAIL_PASSWORD may be left empty.
cat > /go/src/turm/conf/passwords.json <<EOF
{ "db.pw": "${DB_PASSWORD:?DB_PASSWORD is not set}", "email.pw": "${EMAIL_PASSWORD:-}" }
EOF

# Ensure all modules are present and go.sum is up to date.
# Uses the module cache volume so this is fast after the first run.
cd /go/src/turm
go mod download

# Run from /go/src so that utils.DirExists("turm") resolves correctly:
# revel run parses args with a plain os.Stat, so the import path must be
# a directory name relative to CWD, not to GOPATH.
cd /go/src
exec revel run turm docker
