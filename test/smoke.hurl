# Smoke test, run through nginx against a base URL without a trailing slash:
#
#   hurl --test --variable base=https://app.example.org smoke.hurl
#
# package.nix runs it in checkPhase, the NixOS VM test runs it through the
# deployed nginx, and `<name>-smoke BASE_URL` runs it against a live host.
# `file,` paths are relative to this file's directory.

# A server-rendered page, byte for byte.
GET {{base}}/Main/hello/World.21
HTTP 200
[Asserts]
header "Content-Type" contains "text/html"
bytes == file,index.expected.html;

# Reads the GIT_REV environment variable ("unknown" when unset).
GET {{base}}/Main/gitRev
HTTP 200
[Asserts]
body contains "<body>"

# A client-side page and the RPC it calls: an argument-less POST.
GET {{base}}/Main/users
HTTP 200

POST {{base}}/User/getAll
Content-Type: text/plain
HTTP 200

# Unknown paths are 404.
GET {{base}}/Main/nope
HTTP 404
