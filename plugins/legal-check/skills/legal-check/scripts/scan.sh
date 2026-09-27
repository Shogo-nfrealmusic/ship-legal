#!/usr/bin/env bash
# legal-check scanner v2. Read-only. Prints evidence (file:line: snippet) per key, grouped
# in sections. It does not decide PASS or RISK; the skill does that after reading.
#
# Usage:
#   bash scan.sh [PROJECT_DIR]          scan a project (default: current directory)
#   bash scan.sh --recipe NAME[,NAME]   print fix recipes (names: see RECIPES below)
#
# Portable: bash 3.2 + BSD grep (macOS) and GNU tools. Uses perl (present on macOS and
# nearly every Linux) for multi-line checks; those keys say "(perl missing)" without it.
# Secret values are never printed: long tokens on secret lines are redacted.
set -u
LC_ALL=C; export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"
RECIPES="age-screen fonts replay consent email sms renewal payments dmca ugc policies deletion a11y secrets database admin-auth rate-limit ai-disclosure claims"

if [ "${1:-}" = "--recipe" ]; then
  names="$(printf '%s' "${2:-}" | tr ',' ' ')"
  [ -n "$names" ] || { echo "usage: scan.sh --recipe NAME[,NAME...]" >&2; exit 2; }
  for name in $names; do
    case " $RECIPES " in *" $name "*) ;; *) echo "unknown recipe: $name (known: $RECIPES)" >&2; exit 2 ;; esac
  done
  for name in $names; do
    echo "######## recipe: $name"
    cat "$HERE/../recipes/$name.md" || exit 2
    echo
  done
  exit 0
fi

ROOT="${1:-.}"
if [ ! -d "$ROOT" ]; then
  echo "not a directory: $ROOT" >&2
  exit 2
fi
cd "$ROOT" || exit 2

MAX_HITS=6      # evidence lines per key
MAX_LEN=150     # characters per evidence line
HAVE_PERL=0; command -v perl >/dev/null 2>&1 && HAVE_PERL=1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CODE="$TMP/code"    # NUL-separated source files
ENVF="$TMP/envf"    # NUL-separated .env* files (not examples)
ALL="$TMP/all"      # newline list of every non-ignored path

PRUNE='-name node_modules -o -name .git -o -name .next -o -name .nuxt -o -name .output -o -name .svelte-kit -o -name .vercel -o -name .turbo -o -name .claude -o -name dist -o -name build -o -name out -o -name coverage -o -name vendor -o -name .venv -o -name venv -o -name __pycache__ -o -name .cache -o -name .superpowers -o -name .wrangler -o -name .netlify -o -name .amplify -o -name .expo -o -name .yarn -o -name .astro -o -name .docusaurus -o -name storybook-static -o -name target -o -name Pods -o -name site-packages -o -name .terraform -o -name .pytest_cache -o -name .gradle -o -name .dart_tool'

# shellcheck disable=SC2086
find . \( -type d \( $PRUNE \) -prune \) -o -type f -size -1000k -print 2>/dev/null | sed 's|^\./||' > "$ALL"

grep -E '\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte|astro|html|htm|css|scss|sass|less|mdx|py|rb|php|go|erb|ejs|hbs|handlebars|liquid|njk|twig|jinja|jinja2|j2|sql|rules)$|(^|/)(package\.json|app\.json|app\.config\.(js|ts)|manifest\.json|site\.webmanifest|database\.rules\.json|firebase\.json|requirements[^/]*\.txt|pyproject\.toml|Gemfile|composer\.json)$|(^|/)\.env\.example$' "$ALL" \
  | grep -vE '\.min\.(js|css)$|(^|/)(package-lock|pnpm-lock|yarn)\.' \
  | tr '\n' '\0' > "$CODE"
grep -E '(^|/)\.env(\.[A-Za-z0-9_-]+)?$' "$ALL" | grep -vE '\.(example|sample|template|dist)$' | tr '\n' '\0' > "$ENVF"

FILES_SCANNED="$(tr -cd '\0' < "$CODE" | wc -c | tr -d ' ')"

# grep_files LISTFILE REGEX [FLAGS] [OUT] -> raw "file:line:text" hits in OUT (default $TMP/hits)
grep_files() {
  list="$1"; re="$2"; flags="${3--i}"; gout="${4:-$TMP/hits}"
  if [ -s "$list" ]; then
    # shellcheck disable=SC2086
    xargs -0 grep -nHE $flags -e "$re" -- < "$list" 2>/dev/null > "$gout"
  else
    : > "$gout"
  fi
}

# Parallel jobs: each async key prints a placeholder line now and writes its real output
# to its own file; the placeholders are expanded in order at the end.
J=0
PAR="$( (getconf _NPROCESSORS_ONLN || sysctl -n hw.ncpu) 2>/dev/null | head -n 1)"
case "$PAR" in ''|*[!0-9]*) PAR=4 ;; esac
[ "$PAR" -gt 8 ] && PAR=8
job_start() { J=$((J+1)); JF="$TMP/job.$J"; echo "@@JOB $J@@"; }
job_throttle() { if [ $((J % PAR)) -eq 0 ]; then wait; fi; }

print_hits() {
  key="$1"; f="$2"; redact="${3:-}"
  n="$(wc -l < "$f" | tr -d ' ')"
  if [ "$n" -eq 0 ]; then
    echo "$key: (none)"
    return
  fi
  if [ -n "$redact" ]; then
    # Never print secret values: known key prefixes, .env values, and long runs with digits.
    if [ "$HAVE_PERL" -eq 1 ]; then
      head -n "$MAX_HITS" "$f" | perl -pe '
        s/((?:sk_live_|rk_live_|sk_test_|sk-proj-|sk-ant-|sk-|AKIA|ghp_|github_pat_|xox[baprs]-|SG\.)[A-Za-z0-9]{0,2})[A-Za-z0-9_.\-]{4,}/$1…(redacted)/g;
        s/^([^:]*\.env[^:]*:\d+:\s*[A-Za-z0-9_]+\s*=\s*["\x27]?)(.{0,3})[^\s"\x27]+/$1$2…(redacted)/;
        s/([A-Za-z0-9+\/_.\-]{4})(?=[A-Za-z0-9+\/_.\-]*\d)[A-Za-z0-9+\/_.\-]{16,}/$1…(redacted)/g;
        s/\s+/ /g; $_ .= "\n"' | cut -c1-"$MAX_LEN" | sed "s|^|$key: |"
    else
      head -n "$MAX_HITS" "$f" | sed -E 's/[[:space:]]+/ /g; s/([=:"'"'"'`]|Bearer )([^=:"'"'"'` ]{4})[^"'"'"'` ,;]{6,}/\1\2…(redacted)/g' | cut -c1-"$MAX_LEN" | sed "s|^|$key: |"
    fi
  else
    head -n "$MAX_HITS" "$f" | sed -E 's/[[:space:]]+/ /g' | cut -c1-"$MAX_LEN" | sed "s|^|$key: |"
  fi
  if [ "$n" -gt "$MAX_HITS" ]; then
    echo "$key: (+$((n - MAX_HITS)) more)"
  fi
}

# emit KEY REGEX [FLAGS] — grep source files (async)
emit() {
  job_start
  ( grep_files "$CODE" "$2" "${3--i}" "$JF.hits"; print_hits "$1" "$JF.hits" > "$JF" ) &
  job_throttle
}
# files_matching PATH_REGEX -> NUL list of source files in $TMP/sub
files_matching() { tr '\0' '\n' < "$CODE" | grep -iE "$1" | tr '\n' '\0' > "$TMP/sub"; }
# emit_in KEY PATH_REGEX REGEX — grep only source files whose path matches PATH_REGEX (async)
emit_in() {
  files_matching "$2"; job_start; cp "$TMP/sub" "$JF.list"
  ( grep_files "$JF.list" "$3" -i "$JF.hits"; print_hits "$1" "$JF.hits" > "$JF" ) &
  job_throttle
}
# emit_files KEY REGEX [FLAGS] — match on file paths
emit_files() {
  # shellcheck disable=SC2086
  grep ${3:--i} -E "$2" "$ALL" > "$TMP/hits" 2>/dev/null || : > "$TMP/hits"
  print_hits "$1" "$TMP/hits"
}
# perl_scan KEY PERL_CODE LISTFILE — slurp-mode perl over each file; prints "file:line: text"
perl_scan() {
  key="$1"; code="$2"; list="$3"
  if [ "$HAVE_PERL" -eq 0 ]; then echo "$key: (perl missing)"; return; fi
  job_start; cp "$list" "$JF.list"
  (
    if [ -s "$JF.list" ]; then
      # one perl process over all files, so END blocks see every file
      xargs -0 perl -0777 -ne "$code" -- < "$JF.list" 2>/dev/null > "$JF.hits"
    else
      : > "$JF.hits"
    fi
    print_hits "$key" "$JF.hits" > "$JF"
  ) &
  job_throttle
}

Q="[\"']"      # a quote character, for readability in patterns

{
echo "# legal-check scan v2"
echo "root: $(pwd)"
echo "files_scanned: $FILES_SCANNED"

# ---------------------------------------------------------------- stack
echo "== stack =="
grep -E '(^|/)package\.json$' "$ALL" | tr '\n' '\0' > "$TMP/pkgs"
grep -E '(^|/)(requirements[^/]*\.txt|pyproject\.toml)$' "$ALL" | tr '\n' '\0' > "$TMP/py"
dep()   { [ -s "$TMP/pkgs" ] && xargs -0 grep -lE "\"$1\"[[:space:]]*:" -- < "$TMP/pkgs" >/dev/null 2>&1; }
pydep() { [ -s "$TMP/py" ] && xargs -0 grep -liE "^[[:space:]\"']*$1([[:space:]=<>~!,\"'[]|$)" -- < "$TMP/py" >/dev/null 2>&1; }
path()  { grep -qE "$1" "$ALL"; }
stacks=""
add() { stacks="$stacks $1"; }
dep next && add next
dep nuxt && add nuxt
{ dep vue && ! dep nuxt; } && add vue
dep "@sveltejs/kit" && add sveltekit
{ dep svelte && ! dep "@sveltejs/kit"; } && add svelte
dep astro && add astro
{ dep "@remix-run/react" || dep "@react-router/dev"; } && add remix
dep expo && add expo
{ dep react-native && ! dep expo; } && add react-native
{ dep vite && dep react && ! dep next && ! dep "@remix-run/react" && ! dep "@react-router/dev"; } && add vite-react
dep express && add express
dep hono && add hono
pydep fastapi && add fastapi
pydep flask && add flask
pydep django && add django
{ [ -f Gemfile ] && grep -qE "gem ['\"]rails['\"]" Gemfile; } && add rails
[ -f composer.json ] && add php
if [ -z "$stacks" ] && path '(^|/)index\.html?$'; then add static-html; fi
echo "stack:${stacks:- unknown}"
backends=""
{ dep "@supabase/supabase-js" || dep "@supabase/ssr" || pydep supabase || path '(^|/)supabase/(config\.toml|migrations/)'; } && backends="$backends supabase"
{ dep firebase || dep "firebase-admin" || dep "@react-native-firebase/app" || path '(^|/)(firebase\.json|firestore\.rules)$'; } && backends="$backends firebase"
{ dep "@prisma/client" || dep prisma; } && backends="$backends prisma"
dep "drizzle-orm" && backends="$backends drizzle"
path '(^|/)db/schema\.rb$' && backends="$backends activerecord"
echo "backend:${backends:- (none)}"
builders=""
{ dep lovable-tagger || path '(^|/)\.lovable/'; } && builders="$builders lovable"
path '(^|/)\.bolt/' && builders="$builders bolt"
path '(^|/)(\.replit|replit\.nix)$' && builders="$builders replit"
{ path '(^|/)\.v0/' || grep -qiE 'v0\.dev|built with v0|v0\.app' README.md 2>/dev/null; } && builders="$builders v0"
echo "builder:${builders:- (none)}"
case "$stacks" in
  *expo*|*react-native*) echo "mobile: yes" ;;
  *) if path '(^|/)(ios/[^/]+\.xcodeproj|android/app/build\.gradle)'; then echo "mobile: yes"; else echo "mobile: no"; fi ;;
esac
emit framework '"(next|react|vue|nuxt|svelte|@sveltejs/kit|astro|@remix-run/[a-z]+|@react-router/[a-z]+|vite|expo|react-native|express|hono)"[[:space:]]*:|^[[:space:]]*"?(django|flask|fastapi|starlette|rails|laravel/framework)"?[[:space:]]*([=<>~!:,\[]|$)'
if [ -f package.json ]; then
  echo "package_json: yes"
  if [ -d node_modules ]; then echo "node_modules: yes"; else echo "node_modules: no"; fi
  for pm in pnpm-lock.yaml:pnpm yarn.lock:yarn bun.lockb:bun bun.lock:bun package-lock.json:npm; do
    if [ -f "${pm%%:*}" ]; then echo "package_manager: ${pm##*:}"; break; fi
  done
  scripts=""
  if grep -q '"scripts"' package.json; then
    scripts="$(tr '\n' ' ' < package.json | sed -E 's/.*"scripts"[[:space:]]*:[[:space:]]*\{([^}]*)\}.*/\1/' | grep -oE '"[^"]+"[[:space:]]*:' | sed -E 's/^"([^"]+)".*/\1/' | tr '\n' ' ')"
  fi
  echo "scripts: ${scripts:-(none)}"
else
  echo "package_json: no"
fi
for v in .venv venv env; do if [ -x "$v/bin/python" ]; then echo "python_env: $v"; break; fi; done
tests=""
{ path '(^|/)(pytest\.ini|conftest\.py)$' || grep -qs '\[tool\.pytest' pyproject.toml; } && tests="$tests pytest"
{ dep vitest || path '(^|/)vitest\.config\.'; } && tests="$tests vitest"
{ dep jest || path '(^|/)jest\.config\.'; } && tests="$tests jest"
dep "@playwright/test" && tests="$tests playwright"
path '(^|/)spec/.*_spec\.rb$' && tests="$tests rspec"
echo "tests:${tests:- (none)}"

# ---------------------------------------------------------------- age
echo "== coppa =="
emit signup "type=${Q}password${Q}|secureTextEntry|<SignUp[[:space:]/>]|signUp\(|sign_up\(|createUserWithEmailAndPassword|signInWithOAuth|signInWithOtp|signInWithPopup|signInWithRedirect|auth\.admin\.createUser|registerUser\(|createAccount\(|[^a-zA-Z_.]signIn\(${Q}(google|github|apple|facebook|discord|email|resend|credentials)|UserCreationForm|devise|has_secure_password|@app\.(post|route)\(${Q}/(signup|register)"
emit email_capture "type=${Q}email${Q}|keyboardType=${Q}email-address${Q}"
emit age_screen 'birth[_ -]?(date|day|year|month)|date_?of_?birth|\bdob\b|ageGate|age_gate|age[_ -]?verif|isOver13|over_?13|under_?13|13 or older|at least 13|\bage[[:space:]]*(<|>|<=|>=)[[:space:]]*1[0-9]\b'
emit child_signals '\bkids\b|for kids|kid-friendly|for children|children.s (app|game|learning|book)|\bpreschool|kindergarten|toddler|elementary school|grade school|\bages? [0-9]{1,2}[[:space:]]*(-|to)[[:space:]]*1[0-2]\b|\bcoppa\b'

# ---------------------------------------------------------------- privacy & tracking
echo "== fonts =="
emit google_cdn 'fonts\.googleapis\.com|fonts\.gstatic\.com'
emit next_font_google "from[[:space:]]+${Q}next/font/google${Q}"
emit self_hosted 'next/font/local|@fontsource|@font-face|@nuxt/fonts|expo-font|useFonts\('

echo "== replay =="
emit sdk '"(posthog-js|posthog-react-native|@posthog/[a-z-]+|@microsoft/clarity|react-microsoft-clarity|@hotjar/browser|react-hotjar|logrocket|logrocket-react|@logrocket/react-native|@fullstory/[a-z-]+|react-fullstory|mouseflow[a-z-]*|smartlook-client|@smartlook/[a-z-]+|@sentry/[a-z-]+|@highlight-run/[a-z-]+|highlight\.run|@openreplay/[a-z-]+|@datadog/browser-rum)"[[:space:]]*:|clarity\.ms/tag|static\.hotjar\.com|cdn\.logrocket|fullstory\.com/s/fs\.js|cdn\.mouseflow\.com|LogRocket\.init|posthog\.init|FS\.init|replayIntegration\(|new Replay\('
emit recording 'session_recording|disable_session_recording|startSessionRecording|replaysSessionSampleRate|replaysOnErrorSampleRate|sessionReplaySampleRate|enableSessionReplay|LogRocket\.init|clarity\(|hj\(|_hjSettings|FS\.init|replayIntegration\('
emit masking 'maskAllInputs|mask_all_inputs|maskInputOptions|maskAllText|inputSanitizer|textSanitizer|privateByDefault|ph-no-capture|data-hj-suppress|data-clarity-mask|data-private|fs-mask|fs-exclude|blockAllMedia'
emit masking_off "(maskAllInputs|mask_all_inputs|maskAllText)${Q}?[[:space:]]*:[[:space:]]*false|inputSanitizer${Q}?[[:space:]]*:[[:space:]]*false|textSanitizer${Q}?[[:space:]]*:[[:space:]]*false"

echo "== tracking =="
emit analytics 'posthog|gtag\(|googletagmanager\.com|google-analytics\.com|@next/third-parties/google|@vercel/analytics|plausible\.io|next-plausible|plausible-tracker|mixpanel|@segment/|cdn\.segment\.com|@amplitude/|amplitude\.com|clarity\.ms|@microsoft/clarity|hotjar|logrocket|fullstory|umami\.is|usefathom|fathom-client|@react-native-firebase/analytics|firebase/analytics'
emit ad_pixels 'fbq\(|connect\.facebook\.net|facebook-pixel|react-facebook-pixel|analytics\.tiktok\.com|ttq\.(load|page|track)|\bAW-[0-9]{6,}|googleadservices|googlesyndication|doubleclick\.net|snap\.licdn\.com|px\.ads\.linkedin\.com|_linkedin_partner_id|static\.ads-twitter\.com|twq\(|pintrk\(|s\.pinimg\.com/ct|rdt\(|redditstatic\.com/ads|bat\.bing\.com|sc-static\.net/scevent|snaptr\(|react-native-fbsdk|expo-tracking-transparency'
emit consent 'cookie[_ -]?consent|consent[_ -]?(banner|manager|mode)|cookiebot|onetrust|cookieyes|termly|iubenda|klaro|osano|opt_out_capturing|opt_in_capturing|optOut\(|optIn\(|hasConsent|analytics_storage|ad_storage|getConsent|setConsent|consentGiven|requestTrackingPermissions'
emit dnss 'do not sell|do-not-sell|doNotSell|your privacy choices|opt[- ]out of (the )?(sale|sharing)|globalPrivacyControl|Sec-GPC'

echo "== privacy =="
emit_files privacy_page '(^|/)[^/]*privacy[^/]*(/|$)'
emit_files terms_page '(^|/)([Tt]erms|TERMS|[Tt]os|TOS|[Ll]egal|LEGAL)([^a-z/][^/]*)?(/|$)' ' '
emit links "(href|to|path)[[:space:]]*[=:][[:space:]]*[\"'{\`][^\"'}\`]*(privacy|terms|/tos([/?#\"'\`]|$)|/legal)"
emit_in terms_content '(terms|tos|legal)' 'liabilit|as is|as-is|disclaim|warrant'
emit_in privacy_content '(privacy|legal)' 'do not sell|opt[- ]out|right to (delete|know|access|correct)|delete (your|my) (data|account)|download or delete|california|ccpa|cpra|gdpr|categories of|third[- ]part(y|ies)|effective|last updated'
emit deletion 'delete[_ -]?(my[_ -])?account|deleteAccount|deleteUser|auth\.admin\.deleteUser|account deletion|close (my|your) account|destroy_account|export (my|your)? ?data|download (my|your) data|data export'

# ---------------------------------------------------------------- email & sms
echo "== email =="
emit sdk '"(resend|@sendgrid/mail|postmark|mailgun\.js|mailgun-js|nodemailer|@aws-sdk/client-sesv?2?|@react-email/[a-z-]+|react-email|@mailchimp/[a-z_-]+|@getbrevo/brevo|sib-api-v3-sdk|loops|@plunk/node|@novu/[a-z-]+|@mailerlite/[a-z-]+|convertkit[a-z-]*)"[[:space:]]*:|^[[:space:]]*(sendgrid|postmarker|resend|mailchimp[a-z_-]*|flask[-_]mail|django-anymail)([[:space:]=<>~!\[]|$)'
emit send "\.emails\.send\(|\.batch\.send\(|\.emails\.create\(|sendMail\(|send_mail\(|sgMail\.send|sendEmail\(|send_email\(|sendEmailWithTemplate|SendEmailCommand|\bmg\.messages\.create\(|api\.mailgun\.net|sendTransactionalEmail|broadcasts\.(create|send)\(|ActionMailer|deliver_(now|later)|smtplib"
emit unsubscribe 'unsubscribe|List-Unsubscribe|opt[ -]?out of (these|marketing|our) emails|email preferences|manage (your )?(email )?(preferences|subscription)'
emit postal_address 'postal[_ -]?address|mailing[_ -]?address|physical[_ -]?address|business[_ -]?address|company[_ -]?address|P\.?O\.? Box'

echo "== sms =="
emit sdk "\"(twilio|messagebird|@vonage/[a-z-]+|vonage|plivo|telnyx|@aws-sdk/client-sns|@aws-sdk/client-pinpoint-sms-voice-v2|textbelt|@sinch/[a-z-]+)\"[[:space:]]*:|require\(${Q}twilio${Q}\)|from twilio|^[[:space:]]*(twilio|vonage|plivo|telnyx)([[:space:]=<>~!]|$)|api\.twilio\.com|textbelt\.com"
emit send 'sendSms|send_sms|sendSMS|\.sms\.send|verify\.v2|PhoneNumber[[:space:]]*:|client\.messages\.create\(|twilio_client\.messages'
emit phone_input "type=${Q}tel${Q}|keyboardType=${Q}phone-pad${Q}|autoComplete=${Q}tel|name=${Q}phone|textContentType=${Q}telephoneNumber"
emit sms_consent '(agree|consent) to receive (text|sms|marketing text)|msg (&|and) data rates|message (&|and) data rates|reply stop|text stop|STOP to (cancel|opt|unsubscribe|end)'

# ---------------------------------------------------------------- payments
echo "== payments =="
emit subscription "mode${Q}?[[:space:]]*[:=][[:space:]]*${Q}subscription${Q}|subscriptions\.create\(|Subscription\.create\(|recurring${Q}?[[:space:]]*:[[:space:]]*\{|buy\.stripe\.com|stripe-pricing-table|\"@lemonsqueezy/[a-z.-]+\"|lemonsqueezy\.com/checkout|\"@paddle/[a-z-]+\"|\"@polar-sh/[a-z-]+\"|\"chargebee[a-z-]*\"|\"@revenuecat/[a-z-]+\"|react-native-purchases|expo-in-app-purchases|react-native-iap"
emit checkout "checkout\.sessions\.create|checkout\.Session\.create|redirectToCheckout|PaymentElement|CardElement|elements\.create\(|buy\.stripe\.com|paypal\.com/sdk|@paypal/|lemonsqueezy\.com/checkout|\"stripe\"[[:space:]]*:"
emit subscribe_ui '>[^<]*(subscribe|go pro|upgrade|start (your )?(free )?trial|buy now)[^<]*<|/mo<|/mo\b|per month|/month|/year|billed (monthly|annually|yearly)'
emit disclosure 'auto[- ]?renew|renews? (automatically|each|every|monthly|annually|yearly)|until (you )?cancel|recurring (charge|billing|payment)|cancel (at )?any ?time'
emit cancel_path 'billingPortal|billing_portal|customer[_-]?portal|cancel_at_period_end|subscriptions\.(cancel|del)\(|cancelSubscription|cancel (your )?subscription|manage (your )?(subscription|billing|plan)|showManageSubscriptions'
emit refund_policy 'refund|cancellation policy|return policy|money[- ]back'
emit fees '(service|processing|booking|convenience|platform|handling|admin(istrative)?) fee|SERVICE_FEE|serviceFee|service_fee|fee_cents|feeCents'
emit card_fields "name=${Q}(card[_-]?(number|num|no)|cc[_-]?(number|num|no)|cvc|cvv|card[_-]?(cvc|cvv|expiry|exp))${Q}|cardNumber|card_number|autocomplete=${Q}cc-(number|csc|exp)|tokens\.create\([^)]*card"

# ---------------------------------------------------------------- security
echo "== security =="
SECRET_RE='sk_live_[A-Za-z0-9]{8,}|rk_live_[A-Za-z0-9]{8,}|sk_test_[A-Za-z0-9]{8,}|sk-(proj-|ant-)?[A-Za-z0-9_-]{16,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|SG\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}|pat[A-Za-z0-9]{10,}\.[A-Za-z0-9]{20,}|key-[0-9A-Za-z]{20,}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|service_role[^,;]*eyJ[A-Za-z0-9_-]{20,}'
grep_files "$CODE" "$SECRET_RE" ""
grep -vE '\.env\.example:|(^|/)(tests?|__tests__|spec)/' "$TMP/hits" > "$TMP/h2" || true
print_hits secrets "$TMP/h2" redact
: > "$TMP/envtracked"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "git_repo: yes"
  tr '\0' '\n' < "$ENVF" | while IFS= read -r f; do
    if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then echo "$f (committed to git)"; fi
  done > "$TMP/envtracked"
else
  echo "git_repo: no"
fi
print_hits env_committed "$TMP/envtracked"
PUB_RE='(NEXT_PUBLIC_|VITE_|EXPO_PUBLIC_|REACT_APP_|NUXT_PUBLIC_|PUBLIC_|GATSBY_)[A-Z0-9_]*(SECRET|SERVICE_ROLE|PRIVATE|OPENAI|ANTHROPIC|CLAUDE|GEMINI|GROQ|REPLICATE|MISTRAL|ELEVENLABS|STRIPE_SK|STRIPE_SECRET|RESEND|SENDGRID|TWILIO_(AUTH|TOKEN)|AIRTABLE|DATABASE_URL|DB_PASS)'
{ tr '\0' '\n' < "$CODE"; tr '\0' '\n' < "$ENVF"; } | tr '\n' '\0' > "$TMP/publist"
grep_files "$TMP/publist" "$PUB_RE" ""
print_hits public_env_secret "$TMP/hits" redact
# Supabase: tables created in SQL (any file) without RLS enabled (in any file)
files_matching '\.sql$'
cp "$TMP/sub" "$TMP/sql"
perl_scan rls_off '
  my $s=$_;
  while ($s =~ /alter\s+table\s+(?:if\s+exists\s+)?(?:only\s+)?(?:"?public"?\.)?"?(\w+)"?\s+enable\s+row\s+level\s+security/gi) { $on{lc $1}=1 }
  while ($s =~ /create\s+table\s+(?:if\s+not\s+exists\s+)?(?:"?(\w+)"?\.)?"?(\w+)"?/gi) {
    my ($sch,$t,$p)=($1,lc $2,$-[0]); next if defined $sch && lc $sch ne "public";
    push @made, [$ARGV, (substr($s,0,$p)=~tr/\n//)+1, $t] }
  END { for (@made) { my ($f,$l,$t)=@$_; print "$f:$l: table $t (no enable row level security)\n" unless $on{$t} } }' "$TMP/sql"
perl_scan public_bucket '
  while (/insert\s+into\s+storage\.buckets[^;]*?values\s*\(([^;]*?)\)\s*;/gis) { my ($m,$p)=($1,$-[0]); next unless $m =~ /\btrue\b/i; my $l=(substr($_,0,$p)=~tr/\n//)+1; (my $x=$m)=~s/\s+/ /g; print "$ARGV:$l: public bucket ($x)\n" }' "$TMP/sql"
grep_files "$TMP/sql" '(for|to)[[:space:]]+(all|insert|update|delete)[^;]*(using|with check)[[:space:]]*\([[:space:]]*true[[:space:]]*\)'
print_hits open_policy "$TMP/hits"
grep -E '(^|/)(firestore\.rules|storage\.rules|database\.rules\.json|[^/]*\.rules)$' "$ALL" | tr '\n' '\0' > "$TMP/rules"
grep_files "$TMP/rules" 'if[[:space:]]+true|allow[[:space:]]+(read|write|read,[[:space:]]*write)[[:space:]]*;|request\.time[[:space:]]*<[[:space:]]*timestamp|"\.(read|write)"[[:space:]]*:[[:space:]]*(true|"true")'
print_hits firebase_rules "$TMP/hits"
# admin routes/pages, and whether the same file mentions any auth check
AUTH_WORDS='auth|session|getUser|currentUser|current_user|requireAdmin|isAdmin|is_admin|role|login_required|staff_member_required|Depends\(|before_action|authorize|authenticate|clerk|protect|middleware|getServerSession|useUser|verify_token|jwt'
check_auth() { if grep -qiE "$AUTH_WORDS" "$1" 2>/dev/null; then echo found; else echo none; fi; }
grep_files "$CODE" "@(app|router|bp|blueprint|api)\.(get|post|put|delete|route|patch)\(${Q}/(api/)?admin|router\.(get|post|put|delete|use)\(${Q}/(api/)?admin|app\.(get|post|put|delete|use)\(${Q}/(api/)?admin|path[[:space:]]*=[[:space:]]*${Q}/admin|path\(${Q}admin|namespace :admin|get ${Q}/admin" ""
: > "$TMP/adm"; while IFS= read -r line; do f="${line%%:*}"; echo "$line [auth: $(check_auth "$f")]" >> "$TMP/adm"; done < "$TMP/hits"
print_hits admin_route "$TMP/adm"
grep -iE '(^|/)(pages|app|routes|src/routes|src/pages|views|templates|screens)/(.*/)?\(?admin\)?(/|\.|$)|(^|/)[Aa]dmin[A-Za-z]*\.(tsx|jsx|vue|svelte|astro|html)$' "$ALL" > "$TMP/ap" || true
: > "$TMP/adm"; while IFS= read -r f; do echo "$f [auth: $(check_auth "$f")]" >> "$TMP/adm"; done < "$TMP/ap"
print_hits admin_page "$TMP/adm"
emit auth_custom 'bcrypt|argon2|scrypt|password_hash|check_password|verify_password|hashlib\.(sha256|md5|sha1)\([^)]*(pw|pass)|compare\([^)]*password|signInWithPassword|passport-local|authenticate\('
emit rate_limit 'rate.?limit|ratelimit|express-rate-limit|@upstash/ratelimit|rate-limiter-flexible|slowapi|flask[-_]limiter|django[-_]ratelimit|rack[-_]attack|throttle|@nestjs/throttler|limiter\.'

# ---------------------------------------------------------------- accessibility
echo "== a11y =="
files_matching '\.(html?|jsx|tsx|vue|svelte|astro|erb|ejs|hbs|jinja2?|j2|njk|twig|liquid|php)$'
cp "$TMP/sub" "$TMP/markup"
perl_scan img_no_alt '
  while (/<img\b((?:[^>{}]|\{[^{}]*\})*)>/gs) { my ($a,$p)=($1,$-[0]); next if $a =~ /\balt\s*=|\{\s*\.\.\./; my $l=(substr($_,0,$p)=~tr/\n//)+1; (my $x=substr($&,0,90))=~s/\s+/ /g; print "$ARGV:$l: $x\n" }' "$TMP/markup"
perl_scan input_no_label '
  my $s=$_; my %for; $for{$1}=1 while $s =~ /(?:\bfor|htmlFor)\s*=\s*\{?\s*["\x27]([\w-]+)/g;
  while ($s =~ /<(input|textarea|select)\b((?:[^>{}]|\{[^{}]*\})*)>/gs) { my ($t,$a,$p)=($1,$2,$-[0]);
    next if $a =~ /type\s*=\s*\{?\s*["\x27](hidden|submit|button|reset|image)\b/i; next if $a =~ /aria-label|aria-labelledby|\{\s*\.\.\./i;
    if ($a =~ /\bid\s*=\s*\{?\s*["\x27]([\w-]+)/ && $for{$1}) { next }
    my $before=substr($s,0,$p); my $lo=rindex($before,"<label"); my $lc=rindex($before,"</label"); next if $lo>=0 && $lo>$lc;
    my $l=($before=~tr/\n//)+1; (my $x=substr($&,0,90))=~s/\s+/ /g; print "$ARGV:$l: $x\n" }' "$TMP/markup"
perl_scan click_no_keyboard '
  while (/<(div|span|li|p|img|section|article|td)\b((?:[^>{}]|\{[^{}]*\})*?)\bon[Cc]lick\b((?:[^>{}]|\{[^{}]*\})*)>/gs) { my ($a,$p)=($2.$3,$-[0]); next if $a =~ /\brole\s*=|tab[Ii]ndex|onKey/; my $l=(substr($_,0,$p)=~tr/\n//)+1; (my $x=substr($&,0,90))=~s/\s+/ /g; print "$ARGV:$l: $x\n" }' "$TMP/markup"
perl_scan html_no_lang '
  while (/<html\b([^>]*)>/gis) { my ($a,$p)=($1,$-[0]); next if $a =~ /\blang\s*=/i; my $l=(substr($_,0,$p)=~tr/\n//)+1; print "$ARGV:$l: <html$a>\n" }' "$TMP/markup"
files_matching '\.(jsx|tsx|js)$'
perl_scan rn_unlabeled '
  next unless /from\s+["\x27]react-native["\x27]/; while (/<(TouchableOpacity|TouchableHighlight|Pressable|TextInput)\b((?:[^>{}]|\{(?:[^{}]|\{[^{}]*\})*\})*)>/gs) { my ($t,$a,$p)=($1,$2,$-[0]); next if $a =~ /accessibilityLabel|aria-label|accessible=\{false\}/; my $l=(substr($_,0,$p)=~tr/\n//)+1; print "$ARGV:$l: <$t> without accessibilityLabel\n" }' "$TMP/sub"
emit outline_none 'outline[[:space:]]*:[[:space:]]*(none|0)([[:space:];}]|$)|outline-none'
emit zoom_disabled 'user-scalable[[:space:]]*=[[:space:]]*(no|0)|maximum-scale[[:space:]]*=[[:space:]]*1(\.0)?([^0-9.]|$)'

# ---------------------------------------------------------------- content & IP
UGC_RE="\.from\(${Q}(posts|comments|messages|reviews|threads|replies)${Q}\)|collection\([^)]*${Q}(posts|comments|messages|reviews)${Q}|^model (Post|Comment|Message|Review)[[:space:]]|class (Post|Comment|Review)\(models\.Model\)|create table[^(]*(posts|comments|reviews)"
echo "== uploads =="
emit upload "type=${Q}file${Q}|${Q}(@vercel/blob|multer|formidable|busboy|uploadthing|@uploadthing/[a-z-]+|cloudinary|next-cloudinary|@aws-sdk/client-s3|@aws-sdk/s3-presigned-post|firebase/storage|@react-native-firebase/storage|@supabase/storage-js|expo-image-picker|react-native-image-picker)${Q}|storage\.from\([^)]*\)\.upload\(|PutObjectCommand|createPresignedPost|uploadBytes(Resumable)?\(|UploadFile|models\.(File|Image)Field|request\.files|has_(one|many)_attached"
emit ugc "$UGC_RE"
emit dmca '\bdmca\b|designated (copyright )?agent|copyright infringement|takedown notice|512\(c\)'
emit_files dmca_page '(^|/)(dmca|copyright)([._-][^/]*)?(/|$)'
emit dmca_route "(path|href|to)[[:space:]]*[=:][[:space:]]*[\"'{\`][^\"'}\`]*/(dmca|copyright)"

echo "== content =="
emit ugc "$UGC_RE"
emit report_block "report (post|user|content|abuse|this)|reportPost|report_post|reportUser|from\(${Q}reports${Q}\)|collection\([^)]*${Q}reports${Q}|block (user|this user)|blockUser|block_user|moderat|flag(ged)? (post|content)"
NAME_RE="<title>[^<]*|\"(name|slug|short_name|productName|displayName)\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|og:site_name[^>]*content=${Q}[^\"']*|FastAPI\([^)]*title=${Q}[^\"']*|APP_NAME[[:space:]]*=[[:space:]]*${Q}[^\"']*"
files_matching '(^|/)(package\.json|app\.json|app\.config\.(js|ts)|manifest\.json|site\.webmanifest)$|\.(html?|jinja2?|j2|erb|vue|svelte|astro|py)$'
grep_files "$TMP/sub" "$NAME_RE" ""
grep -vE '"name"[[:space:]]*:[[:space:]]*"(functions|@[^"]*)"' "$TMP/hits" > "$TMP/names" || true
print_hits app_names "$TMP/names"
BRANDS='chatgpt|gpt|openai|claude|anthropic|gemini|google|apple|iphone|insta|instagram|tiktok|facebook|whatsapp|youtube|netflix|spotify|disney|marvel|pokemon|nintendo|uber|airbnb|amazon|tesla|nike|twitter|linkedin|notion|figma|canva|shopify|paypal|slack|discord|zoom|starbucks|mcdonald|coca-?cola|harry potter|lego|nfl|nba|fifa|olympic'
grep -iE "^[^:]*:[0-9]+:.*\b($BRANDS)" "$TMP/names" > "$TMP/b1" || true
grep_files "$CODE" "(used by|trusted by|loved by|as seen (on|in)|developers at|teams at|engineers? at|customers (at|like|include))[^<\"]{0,80}\b($BRANDS)"
cat "$TMP/hits" >> "$TMP/b1"
print_hits brand_hits "$TMP/b1"
emit ai_sdk '"(openai|@anthropic-ai/sdk|ai|@ai-sdk/[a-z-]+|langchain|@langchain/[a-z-]+|replicate|@google/generative-ai|@google/genai|groq-sdk|together-ai|@fal-ai/[a-z-]+|cohere-ai|@mistralai/mistralai|elevenlabs|@elevenlabs/[a-z-]+)"[[:space:]]*:|^[[:space:]]*(openai|anthropic|langchain[a-z_-]*|google-generativeai|google-genai|replicate|groq)([[:space:]=<>~!\[]|$)|api\.openai\.com|api\.anthropic\.com|generativelanguage\.googleapis\.com|api\.replicate\.com'
emit ai_disclosure "\bAI[- ](generated|assistant|coach|chat|chatbot|bot|model|answer|written|created)|powered by (AI|GPT|OpenAI|Claude|Gemini)|chatting with an? (AI|bot)|(you|you${Q}re|you are) (chatting|talking) (with|to) an? (AI|bot)|this is an AI|generated (by|with) AI|artificial intelligence"
emit persona_denial "never (say|reveal|admit|mention)[^.\"']{0,30}(AI|bot|language model)|pretend (to be|you are|you${Q}re) (a )?human|you are a (real|friendly)? ?human|(not|never) an? (AI|bot)[^-]"
emit testimonials "testimonial|reviews?[[:space:]]*=[[:space:]]*\[|★★★★★|${Q}?stars${Q}?[[:space:]]*:|rating[[:space:]]*:[[:space:]]*[45]|class=${Q}review"
emit claims "(trusted|used|loved) by [0-9][0-9,.]*[kKmM+]*|[0-9][0-9,.]*[kKmM]?\+? (happy |active )?(users|customers|athletes|developers|founders|students|creators|teams|members|clients)|#1 |number one|guaranteed (results|to)|clinically (proven|tested)|doctor[- ]recommended|as seen (on|in)|lose [0-9]+ ?(kg|lbs|pounds)|doubled? (my|your) (output|income|revenue)"

} > "$TMP/main"
wait
# expand placeholders in order
while IFS= read -r line; do
  case "$line" in
    "@@JOB "*"@@") n="${line#@@JOB }"; n="${n%@@}"; cat "$TMP/job.$n" 2>/dev/null ;;
    *) printf '%s\n' "$line" ;;
  esac
done < "$TMP/main"
exit 0
