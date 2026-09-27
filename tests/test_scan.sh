#!/usr/bin/env bash
# Tests for scripts/scan.sh. Run: bash tests/test_scan.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
SCAN="$ROOT/plugins/legal-check/skills/legal-check/scripts/scan.sh"
VIBELY="$ROOT/examples/vibely-sample"
TIDY="$ROOT/examples/tidy-sample"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok   - $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL - $1"; }

# section NAME < output : prints the lines of one "== NAME ==" section
section() { awk -v s="== $1 ==" '$0==s{on=1;next} /^== /{on=0} on'; }
# has OUT SECTION KEY REGEX : a line "KEY: <match>" exists in that section
has()  { printf '%s\n' "$1" | section "$2" | grep -E "^$3: " | grep -qE "$4"; }
none() { printf '%s\n' "$1" | section "$2" | grep -qE "^$3: \(none\)$"; }
expect_has()  { has  "$1" "$2" "$3" "$4" && ok "$5" || bad "$5"; }
expect_none() { none "$1" "$2" "$3"      && ok "$4" || bad "$4"; }

echo "# vibely-sample (six known gaps)"
out="$(bash "$SCAN" "$VIBELY")"; rc=$?
[ $rc -eq 0 ] && ok "exits 0" || bad "exits 0 (got $rc)"
for s in stack coppa fonts replay email renewal uploads policies consent; do
  printf '%s\n' "$out" | grep -qx "== $s ==" && ok "has section $s" || bad "has section $s"
done
expect_has  "$out" coppa   signup        'app/signup/page.tsx:[0-9]+:'           "finds the password sign-up form"
expect_none "$out" coppa   age_screen                                              "no age screen found"
expect_none "$out" coppa   child_signals                                           "no child-directed signals"
expect_has  "$out" fonts   google_cdn    'app/layout.tsx:[0-9]+:.*fonts.googleapis' "finds Google Fonts CDN link"
expect_none "$out" fonts   next_font_google                                        "no next/font/google"
expect_has  "$out" replay  sdk           'package.json:[0-9]+:.*posthog-js'       "finds posthog-js dependency"
expect_has  "$out" replay  masking_off   'app/providers.tsx:[0-9]+:.*maskAllInputs' "finds maskAllInputs: false"
expect_has  "$out" replay  recording     'app/providers.tsx:[0-9]+:.*disable_session_recording' "finds recording config"
expect_has  "$out" email   send          'app/api/waitlist/launch/route.ts:[0-9]+:' "finds Resend batch send"
expect_has  "$out" email   sdk           'package.json:[0-9]+:.*resend'           "finds resend dependency"
expect_none "$out" email   unsubscribe                                             "no unsubscribe found"
expect_none "$out" email   postal_address                                          "no postal address found"
expect_has  "$out" renewal subscription  'app/api/checkout/route.ts:[0-9]+:.*subscription' "finds subscription checkout"
expect_none "$out" renewal disclosure                                              "no renewal disclosure"
expect_none "$out" renewal cancel_path                                             "no cancel path"
expect_has  "$out" uploads upload        'app/settings/profile/page.tsx:[0-9]+:.*type="file"' "finds file input"
expect_has  "$out" uploads upload        'app/api/avatar/route.ts:[0-9]+:.*@vercel/blob' "finds blob upload"
expect_none "$out" uploads dmca                                                    "no DMCA page"
expect_none "$out" policies privacy_page                                           "no privacy page"
expect_none "$out" policies terms_page                                             "no terms page"
expect_none "$out" consent  consent                                                "no consent handling"
expect_has  "$out" consent  analytics    'posthog'                                 "lists posthog as analytics"
if printf '%s\n' "$out" | grep -q 'node_modules/'; then bad "never scans node_modules"; else ok "never scans node_modules"; fi
if printf '%s\n' "$out" | grep -q 'package-lock.json'; then bad "never scans lockfiles"; else ok "never scans lockfiles"; fi
expect_has "$out" stack framework 'next' "detects Next.js"

echo "# tidy-sample (clean control)"
out="$(bash "$SCAN" "$TIDY")"; rc=$?
[ $rc -eq 0 ] && ok "exits 0" || bad "exits 0 (got $rc)"
expect_has  "$out" coppa   age_screen    'app/signup/page.tsx:[0-9]+:'             "finds birth-year age screen"
expect_none "$out" fonts   google_cdn                                               "no Google Fonts CDN"
expect_has  "$out" fonts   next_font_google 'app/layout.tsx'                        "sees next/font/google (self-hosted at build)"
expect_none "$out" replay  masking_off                                              "no masking disabled"
expect_has  "$out" consent consent       'lib/analytics.ts:[0-9]+:.*opt_out_capturing_by_default' "finds consent gating"
expect_has  "$out" email   send          'app/api/reset-password/route.ts'          "finds the reset email send"
expect_none "$out" renewal subscription                                             "no subscription"
expect_none "$out" uploads upload                                                   "no uploads"
expect_has  "$out" policies privacy_page 'app/privacy/page.tsx'                     "finds privacy page"
expect_has  "$out" policies terms_page   'app/terms/page.tsx'                       "finds terms page"
expect_has  "$out" policies links        'app/layout.tsx:[0-9]+:.*privacy'          "finds footer link to privacy"

echo "# the skill's own files must not be scanned"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp -R "$TIDY" "$TMP/app"
mkdir -p "$TMP/app/.claude/skills/legal-check/recipes"
echo '<link href="https://fonts.googleapis.com/css2?family=X">' > "$TMP/app/.claude/skills/legal-check/recipes/fonts.md"
echo '<link href="https://fonts.googleapis.com/css2?family=X">' > "$TMP/app/.claude/skills/legal-check/recipes/fonts.html"
out="$(bash "$SCAN" "$TMP/app")"
expect_none "$out" fonts google_cdn "ignores .claude/ directory"

echo "# a path with spaces works"
mkdir -p "$TMP/my app"; cp -R "$VIBELY/app" "$TMP/my app/app"
out="$(bash "$SCAN" "$TMP/my app")"; rc=$?
[ $rc -eq 0 ] && ok "exits 0 on path with spaces" || bad "exits 0 on path with spaces"
expect_has "$out" fonts google_cdn 'app/layout.tsx' "scans a path with spaces"

echo "# bad input"
bash "$SCAN" "$TMP/does-not-exist" >/dev/null 2>&1 && bad "non-existent dir exits non-zero" || ok "non-existent dir exits non-zero"

echo "# recipes"
r="$(bash "$SCAN" --recipe fonts)"; [ $? -eq 0 ] && printf '%s' "$r" | grep -q 'fontsource\|next/font/local' && ok "--recipe fonts prints the recipe" || bad "--recipe fonts prints the recipe"
for n in age-screen fonts replay email renewal dmca policies; do
  bash "$SCAN" --recipe "$n" >/dev/null 2>&1 && ok "recipe $n exists" || bad "recipe $n exists"
done
r="$(bash "$SCAN" --recipe fonts,email)"; printf '%s' "$r" | grep -q '^######## recipe: fonts' && printf '%s' "$r" | grep -q '^######## recipe: email' && ok "--recipe accepts a comma list" || bad "--recipe accepts a comma list"
bash "$SCAN" --recipe fonts,nope >/dev/null 2>&1 && bad "--recipe rejects an unknown name in a list" || ok "--recipe rejects an unknown name in a list"
expect_has "$(bash "$SCAN" "$VIBELY")" stack scripts 'build.*typecheck' "lists package.json scripts"
bash "$SCAN" --recipe ../scripts/scan >/dev/null 2>&1 && bad "--recipe rejects path traversal" || ok "--recipe rejects path traversal"

echo
echo "passed: $PASS  failed: $FAIL"
[ $FAIL -eq 0 ]
