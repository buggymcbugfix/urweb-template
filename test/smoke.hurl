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

# Unknown paths are 404.
GET {{base}}/Main/nope
HTTP 404
