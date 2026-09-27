#!/usr/bin/env bash
# legal-check scanner. Read-only. Prints evidence (file:line: snippet) for each check.
# It does not decide PASS or RISK; the skill does that after reading the evidence.
#
# Usage:
#   bash scan.sh [PROJECT_DIR]      scan a project (default: current directory)
#   bash scan.sh --recipe NAME      print a fix recipe (age-screen, fonts, replay, email,
#                                   renewal, dmca, policies)
#
# Works with the bash 3.2 and BSD grep that ship with macOS, and with GNU tools.
set -u
LC_ALL=C; export LC_ALL

HERE="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" = "--recipe" ]; then
  # One name or a comma-separated list: --recipe fonts,email
  names="$(printf '%s' "${2:-}" | tr ',' ' ')"
  [ -n "$names" ] || { echo "usage: scan.sh --recipe NAME[,NAME...]" >&2; exit 2; }
  for name in $names; do
    case "$name" in
      age-screen|fonts|replay|email|renewal|dmca|policies) ;;
      *) echo "unknown recipe: $name" >&2; exit 2 ;;
    esac
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

MAX_HITS=8      # evidence lines per key
MAX_LEN=150     # characters per evidence line

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CODE="$TMP/code"    # NUL-separated list of source files to grep
ALL="$TMP/all"      # newline list of every non-ignored path (for filename checks)

PRUNE='-name node_modules -o -name .git -o -name .next -o -name .nuxt -o -name .output -o -name .svelte-kit -o -name .vercel -o -name .turbo -o -name .claude -o -name dist -o -name build -o -name out -o -name coverage -o -name vendor -o -name .venv -o -name venv -o -name __pycache__ -o -name .cache -o -name .superpowers'

# shellcheck disable=SC2086
find . \( -type d \( $PRUNE \) -prune \) -o -type f -print 2>/dev/null | sed 's|^\./||' > "$ALL"

grep -E '\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte|astro|html|htm|css|scss|sass|less|mdx|py|rb|php|go|erb|ejs|hbs|handlebars|liquid|njk|twig|jinja|jinja2)$|(^|/)package\.json$|(^|/)\.env\.example$' "$ALL" \
  | grep -vE '\.min\.(js|css)$|(^|/)(package-lock|pnpm-lock|yarn)\.' \
  | tr '\n' '\0' > "$CODE"

FILES_SCANNED="$(tr -cd '\0' < "$CODE" | wc -c | tr -d ' ')"

# emit KEY REGEX [FLAGS]  — grep code files, print "KEY: file:line: snippet"
emit() {
  key="$1"; re="$2"; flags="${3:--i}"
  if [ "$FILES_SCANNED" -gt 0 ]; then
    xargs -0 grep -nHE $flags -e "$re" -- < "$CODE" 2>/dev/null > "$TMP/hits"
  else
    : > "$TMP/hits"
  fi
  print_hits "$key" "$TMP/hits"
}

# emit_files KEY REGEX — match on file paths instead of content
emit_files() {
  key="$1"; re="$2"
  grep -iE "$re" "$ALL" > "$TMP/hits" 2>/dev/null || : > "$TMP/hits"
  print_hits "$key" "$TMP/hits"
}

print_hits() {
  key="$1"; f="$2"
  n="$(wc -l < "$f" | tr -d ' ')"
  if [ "$n" -eq 0 ]; then
    echo "$key: (none)"
    return
  fi
  head -n "$MAX_HITS" "$f" | sed -E 's/[[:space:]]+/ /g' | cut -c1-"$MAX_LEN" | sed "s|^|$key: |"
  if [ "$n" -gt "$MAX_HITS" ]; then
    echo "$key: (+$((n - MAX_HITS)) more)"
  fi
}

echo "# legal-check scan v1"
echo "root: $(pwd)"
echo "files_scanned: $FILES_SCANNED"

echo "== stack =="
emit framework '"(next|react|vue|nuxt|svelte|@sveltejs/kit|astro|@remix-run/[a-z]+|@react-router/[a-z]+|vite|express|hono|django|flask|rails|laravel/framework)"[[:space:]]*:'
if [ -f package.json ]; then
  echo "package_json: yes"
  if [ -d node_modules ]; then echo "node_modules: yes"; else echo "node_modules: no"; fi
  for pm in pnpm-lock.yaml:pnpm yarn.lock:yarn bun.lockb:bun bun.lock:bun package-lock.json:npm; do
    if [ -f "${pm%%:*}" ]; then echo "package_manager: ${pm##*:}"; break; fi
  done
  scripts="$(sed -n '/"scripts"[[:space:]]*:/,/}/p' package.json | grep -oE '"[a-zA-Z0-9:_-]+"[[:space:]]*:' | sed -E 's/^"([^"]+)".*/\1/' | grep -vx scripts | tr '\n' ' ')"
  echo "scripts: ${scripts:-(none)}"
else
  echo "package_json: no"
fi

echo "== coppa =="
emit signup 'type=["'"'"']password["'"'"']|<SignUp[[:space:]/>]|signUp\(|sign_up\(|createUserWithEmailAndPassword|signInWithOAuth|auth\.admin\.createUser|registerUser\(|createAccount\('
emit age_screen 'birth[_ -]?(date|day|year|month)|date_?of_?birth|\bdob\b|ageGate|age_gate|age[_ -]?verif|isOver13|over_?13|under_?13|13 or older|at least 13|\bage[[:space:]]*(<|>|<=|>=)[[:space:]]*1[0-9]\b'
emit child_signals '\bkids?\b|for children|children.s (app|game|learning|book)|\bpreschool|kindergarten|toddler|elementary school|grade school|\bages? [0-9]{1,2}[[:space:]]*(-|to)[[:space:]]*1[0-2]\b|\bcoppa\b'

echo "== fonts =="
emit google_cdn 'fonts\.googleapis\.com|fonts\.gstatic\.com'
emit next_font_google 'from[[:space:]]+["'"'"']next/font/google["'"'"']'
emit self_hosted 'next/font/local|@fontsource|@font-face'

echo "== replay =="
emit sdk '"(posthog-js|posthog-node|@posthog/[a-z-]+|@microsoft/clarity|react-microsoft-clarity|@hotjar/browser|react-hotjar|logrocket|logrocket-react|@fullstory/[a-z-]+|react-fullstory|mouseflow[a-z-]*|smartlook-client|@smartlook/[a-z-]+|@sentry/[a-z-]+|@highlight-run/[a-z-]+|highlight\.run|@openreplay/[a-z-]+|@datadog/browser-rum)"[[:space:]]*:|clarity\.ms/tag|static\.hotjar\.com|cdn\.logrocket|fullstory\.com/s/fs\.js|cdn\.mouseflow\.com|LogRocket\.init|posthog\.init|FS\.init|replayIntegration\(|new Replay\('
emit recording 'session_recording|disable_session_recording|startSessionRecording|replaysSessionSampleRate|replaysOnErrorSampleRate|sessionReplaySampleRate|LogRocket\.init|clarity\(|hj\(|FS\.init|replayIntegration\('
emit masking 'maskAllInputs|mask_all_inputs|maskInputOptions|maskAllText|inputSanitizer|textSanitizer|privateByDefault|ph-no-capture|data-hj-suppress|data-clarity-mask|data-private|fs-mask|fs-exclude|blockAllMedia'
emit masking_off '(maskAllInputs|mask_all_inputs|maskAllText)["'"'"']?[[:space:]]*:[[:space:]]*false|inputSanitizer["'"'"']?[[:space:]]*:[[:space:]]*false|textSanitizer["'"'"']?[[:space:]]*:[[:space:]]*false'

echo "== consent =="
emit analytics 'posthog|gtag\(|googletagmanager\.com|google-analytics\.com|@next/third-parties/google|@vercel/analytics|plausible|mixpanel|@segment/|cdn\.segment\.com|amplitude|fbq\(|connect\.facebook\.net|ttq\.|clarity\.ms|hotjar|logrocket|fullstory|umami|fathom'
emit consent 'cookie[_ -]?consent|consent[_ -]?(banner|manager|mode)|cookiebot|onetrust|cookieyes|termly|iubenda|klaro|opt_out_capturing|opt_in_capturing|optOut\(|optIn\(|hasConsent|analytics_storage|ad_storage|getConsent|setConsent|consentGiven'

echo "== email =="
emit sdk '"(resend|@sendgrid/mail|postmark|mailgun\.js|mailgun-js|nodemailer|@aws-sdk/client-sesv?2?|@react-email/[a-z-]+|react-email|@mailchimp/[a-z_-]+|@getbrevo/brevo|sib-api-v3-sdk|loops|@plunk/node|@novu/[a-z-]+|@mailerlite/[a-z-]+|convertkit[a-z-]*)"[[:space:]]*:'
emit send '\.emails\.send\(|\.batch\.send\(|\.emails\.create\(|sendMail\(|sgMail\.send|sendEmail\(|sendEmailWithTemplate|SendEmailCommand|messages\.create\(|sendTransactionalEmail|broadcasts\.(create|send)\('
emit unsubscribe 'unsubscribe|List-Unsubscribe|opt[ -]?out of (these|marketing|our) emails|email preferences|manage (your )?(email )?(preferences|subscription)'
emit postal_address 'postal[_ -]?address|mailing[_ -]?address|physical[_ -]?address|business[_ -]?address|company[_ -]?address|P\.?O\.? Box'

echo "== renewal =="
emit subscription 'mode["'"'"']?[[:space:]]*:[[:space:]]*["'"'"']subscription["'"'"']|subscriptions\.create\(|recurring["'"'"']?[[:space:]]*:[[:space:]]*\{|buy\.stripe\.com|stripe-pricing-table|"@lemonsqueezy/[a-z.-]+"|"@paddle/[a-z-]+"|"@polar-sh/[a-z-]+"|"chargebee[a-z-]*"|"@revenuecat/[a-z-]+"'
emit subscribe_ui '>[^<]*(subscribe|go pro|upgrade|start (your )?(free )?trial|buy now)[^<]*<|/mo<|/mo\b|per month|/month|/year|billed (monthly|annually|yearly)'
emit disclosure 'auto[- ]?renew|renews? (automatically|each|every|monthly|annually|yearly)|until (you )?cancel|recurring (charge|billing|payment)|cancel (at )?any ?time'
emit cancel_path 'billingPortal|billing_portal|customer[_-]?portal|cancel_at_period_end|subscriptions\.(cancel|del)\(|cancelSubscription|cancel (your )?subscription|manage (your )?(subscription|billing|plan)'

echo "== uploads =="
emit upload 'type=["'"'"']file["'"'"']|["'"'"'](@vercel/blob|multer|formidable|busboy|uploadthing|@uploadthing/[a-z-]+|cloudinary|next-cloudinary|@aws-sdk/client-s3|@aws-sdk/s3-presigned-post|firebase/storage|@supabase/storage-js)["'"'"']|storage\.from\([^)]*\)\.upload\(|PutObjectCommand|createPresignedPost|uploadBytes(Resumable)?\('
emit dmca '\bdmca\b|designated (copyright )?agent|copyright infringement|takedown notice|512\(c\)'
emit_files dmca_page '(^|/)[^/]*(dmca|copyright)[^/]*(/|$)'

echo "== policies =="
emit_files privacy_page '(^|/)[^/]*privacy[^/]*(/|$)'
emit_files terms_page '(^|/)[^/]*(terms|tos|terms-of-service|terms-of-use|legal)[^/]*(/|$)'
emit links 'href=["'"'"'{][^"'"'"'}]*(privacy|terms|tos|legal)'

exit 0
