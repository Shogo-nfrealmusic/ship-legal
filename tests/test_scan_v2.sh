#!/usr/bin/env bash
# v2 scanner tests: stack detection and the broader checks, on the v2 sample apps.
# Run: bash tests/test_scan_v2.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
SCAN="$ROOT/plugins/legal-check/skills/legal-check/scripts/scan.sh"
EX="$ROOT/examples"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok   - $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL - $1"; }
section() { awk -v s="== $1 ==" '$0==s{on=1;next} /^== /{on=0} on'; }
has()  { printf '%s\n' "$1" | section "$2" | grep -E "^$3: " | grep -qE "$4"; }
none() { printf '%s\n' "$1" | section "$2" | grep -qE "^$3: \(none\)$"; }
H() { has  "$OUT" "$1" "$2" "$3" && ok "$4" || bad "$4"; }
N() { none "$OUT" "$1" "$2"      && ok "$3" || bad "$3"; }
NOT() { if printf '%s\n' "$OUT" | grep -qE "$1"; then bad "$2"; else ok "$2"; fi; }

echo "# lovable-vite-supabase"
OUT="$(bash "$SCAN" "$EX/lovable-vite-supabase")"
H stack stack 'vite-react' "stack: vite-react"
H stack backend 'supabase' "backend: supabase"
H stack builder 'lovable' "builder: lovable"
H security public_env_secret '\.env:[0-9]+:.*VITE_OPENAI_API_KEY' "VITE_OPENAI_API_KEY is exposed to the browser"
NOT 'VITE_SUPABASE_ANON_KEY' "anon key is never reported"
NOT 'sk-proj-FAKE-DEMO|sk-proj-FAKEdemo' "secret values are redacted from output"
H security rls_off 'profiles' "profiles table has RLS off"
H security rls_off 'posts' "posts table has RLS off"
H security public_bucket 'photos' "public storage bucket"
H security admin_page 'src/pages/Admin.tsx.*auth: none' "admin page without auth"
H tracking ad_pixels 'index.html:[0-9]+:.*fbq' "Meta Pixel"
N tracking consent "no consent"
N tracking dnss "no Do Not Sell link"
H a11y img_no_alt 'src/pages/Landing.tsx:[0-9]+' "img without alt (multi-attr JSX)"
H a11y img_no_alt 'src/pages/Feed.tsx:[0-9]+' "img without alt in feed"
H a11y input_no_label 'src/pages/Signup.tsx:[0-9]+' "inputs with only placeholders"
H a11y click_no_keyboard 'src/pages/Coach.tsx:[0-9]+' "clickable div"
H a11y zoom_disabled 'index.html' "zoom disabled"
H a11y outline_none 'src/index.css' "focus outline removed"
H content ai_sdk 'api.openai.com' "LLM call"
H content persona_denial 'Never say you are an AI' "bot told to deny being AI"
H content testimonials 'Landing.tsx' "hardcoded testimonials"
H content claims 'Trusted by 50,000' "numeric claim"
H content ugc 'posts' "UGC posts"
N content report_block "no report/block"
N privacy deletion "no account deletion"

echo "# html-stripe-landing"
OUT="$(bash "$SCAN" "$EX/html-stripe-landing")"
H stack stack 'static-html' "stack: static-html"
H stack builder 'bolt' "builder: bolt"
H payments subscription 'buy.stripe.com' "Stripe payment link"
N payments refund_policy "no refund policy"
N payments disclosure "no renewal disclosure"
H tracking ad_pixels 'analytics.tiktok.com|ttq' "TikTok pixel"
H tracking ad_pixels 'AW-987654321' "Google Ads tag"
H replay sdk 'hotjar' "Hotjar"
H security secrets 'js/app.js:[0-9]+:.*AIRTABLE' "Airtable token in client JS"
NOT 'patFAKEdemo0000' "Airtable token value redacted"
H sms phone_input 'type="tel"' "phone input"
N sms sms_consent "no SMS consent text"
H a11y img_no_alt 'index.html:[0-9]+' "HTML img without alt"
H a11y click_no_keyboard 'index.html:[0-9]+.*onclick' "div onclick"
H content claims '120,000 developers|#1' "numeric/#1 claims"
H content brand_hits 'Google|Apple' "big brands named in claims"

echo "# expo-firebase-app"
OUT="$(bash "$SCAN" "$EX/expo-firebase-app")"
H stack stack 'expo' "stack: expo"
H stack backend 'firebase' "backend: firebase"
H stack mobile 'yes' "mobile: yes"
H security firebase_rules 'firestore.rules:[0-9]+:.*request.time' "Firestore test-mode rules"
H security firebase_rules 'storage.rules:[0-9]+:.*if true' "Storage open rules"
H security public_env_secret 'EXPO_PUBLIC_OPENAI_API_KEY' "EXPO_PUBLIC OpenAI key"
NOT 'EXPO_PUBLIC_FIREBASE_API_KEY' "Firebase web API key is not reported"
H coppa signup 'app/index.tsx:[0-9]+:.*createUserWithEmailAndPassword' "Firebase sign-up"
H sms sdk 'twilio' "Twilio"
H sms phone_input 'phone-pad' "RN phone input"
H content app_names 'InstaVibe' "app name"
H content brand_hits 'InstaVibe' "Insta* name flagged for trademark review"
N privacy deletion "no account deletion"
H a11y rn_unlabeled 'app/feed.tsx:[0-9]+' "RN touchable without label"

echo "# fastapi-shop"
OUT="$(bash "$SCAN" "$EX/fastapi-shop")"
H stack stack 'fastapi' "stack: fastapi"
H stack builder 'replit' "builder: replit"
H stack tests 'pytest' "pytest detected"
H security secrets 'app/config.py:[0-9]+:.*STRIPE_SECRET_KEY' "hardcoded Stripe live key"
NOT 'sk_live_FAKEdemo1234' "Stripe key value redacted"
H security admin_route 'app/main.py:[0-9]+:.*/admin/orders.*auth: none' "unauthenticated admin route"
H security auth_custom 'app/main.py' "custom password auth"
N security rate_limit "no rate limit"
H payments card_fields 'card_number' "raw card fields"
H payments fees 'SERVICE_FEE' "service fee"
H email send 'mailgun' "Mailgun send"
H uploads upload 'UploadFile' "uploads"
H fonts google_cdn 'base.html' "Google Fonts in Jinja template"

echo "# clean-vite-supabase (no false positives)"
OUT="$(bash "$SCAN" "$EX/clean-vite-supabase")"
H stack stack 'vite-react' "stack: vite-react"
N security rls_off "all tables have RLS"
N security secrets "no hardcoded secrets"
N security public_env_secret "no secret in public env"
NOT 'SUPABASE_SERVICE_ROLE_KEY.*public_env_secret|public_env_secret.*SERVICE_ROLE' "server-side service role not flagged"
N a11y img_no_alt "all images have alt"
N a11y input_no_label "all inputs labelled"
N a11y click_no_keyboard "no clickable divs"
N a11y outline_none "focus outline kept"
N tracking ad_pixels "no ad pixels"
H tracking analytics 'plausible.io' "cookieless analytics seen"
N content brand_hits "'continue with Google' is not a trademark hit"
H content report_block 'Report post' "report path"
H content ai_disclosure "chatting with an AI" "AI disclosure"
N content persona_denial "no persona denial"
H privacy deletion 'deleteUser|Delete my account' "account deletion"
H privacy terms_content 'liability' "terms limit liability"
H uploads dmca_route "/copyright" "copyright page (route)"
N fonts google_cdn "self-hosted fonts"

echo "# every recipe the skill can ask for exists"
for n in age-screen fonts replay consent email sms renewal payments dmca ugc policies deletion a11y secrets database admin-auth rate-limit ai-disclosure claims; do
  bash "$SCAN" --recipe "$n" 2>/dev/null | grep -q "^## Done when" && ok "recipe $n has a Done-when section" || bad "recipe $n has a Done-when section"
done

echo "# speed on a large tree (generated, 3000 files)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
for d in $(seq 1 30); do mkdir -p "$T/src/m$d"; for f in $(seq 1 100); do
  printf 'import React from "react";\nexport function C%s() { return <div className="x"><p>Item %s</p></div>; }\n' "$f" "$f" > "$T/src/m$d/c$f.tsx"; done; done
echo '{"name":"big","dependencies":{"react":"19.0.0","vite":"6.0.0"}}' > "$T/package.json"
s=$(date +%s); bash "$SCAN" "$T" > /dev/null; e=$(( $(date +%s) - s ))
[ "$e" -lt 90 ] && ok "scan of 3000 files finishes under 90 s (${e}s)" || bad "scan of 3000 files finishes under 90 s (${e}s)"

echo
echo "passed: $PASS  failed: $FAIL"
[ $FAIL -eq 0 ]
