FROM golang:1.24-bookworm

# Install the Revel CLI.
# revel/cmd v1.1.x uses golang.org/x/tools v0.1.10, which contains a nil-pointer
# bug in GetSizesGolist that panics with Go 1.22+. The fix is in x/tools v0.24.0+.
# We build revel/cmd inside a throw-away module so that Go's MVS selects the
# higher x/tools version, while the actual binary remains v1.1.2.
RUN mkdir /tmp/revel-build \
    && cd /tmp/revel-build \
    && go mod init revel-build \
    && go get github.com/revel/cmd@v1.1.2 \
    && go get golang.org/x/tools@v0.26.0 \
    && go build -mod=mod -o /go/bin/revel github.com/revel/cmd/revel \
    && cd / && rm -rf /tmp/revel-build

WORKDIR /go/src/turm

# Download Go module dependencies as a separate layer so they are cached
# across source-only rebuilds. go.sum is created here if it does not yet exist.
COPY go.mod .
RUN touch go.sum && go mod download

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000
ENTRYPOINT ["/entrypoint.sh"]
