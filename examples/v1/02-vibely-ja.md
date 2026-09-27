# 02-vibely-ja

Prompt: `/legal-check このアプリ、法的に大丈夫？  →  はい、お願いします`

## Turn 1

Wall time 45 s · cost $0.60 at API list prices · 14 tool calls

legal-check · vibely-ja · 8 RISK · 0 PASS · 0 N/A

```
 #  Check                          Status  Where
 1  Kids under 13 (COPPA)          RISK    app/signup/page.tsx:31
 2  Google Fonts CDN (GDPR, EU)    RISK    app/layout.tsx:17
 3  Session replay (CIPA)          RISK    app/providers.tsx:15
 4  Marketing email (CAN-SPAM)     RISK    emails/launch-announcement.ts:11
 5  Subscriptions (CA renewal)     RISK    app/pricing/page.tsx:19
 6  User uploads (DMCA)            RISK    app/api/avatar/route.ts:11
 7  Privacy policy & terms         RISK    -
 8  Analytics consent              RISK    app/providers.tsx:9
```

**── 1 · Kids under 13 (COPPA) · RISK**
- **見つかったもの:** `app/signup/page.tsx:31` のサインアップはメールと名前を集めますが、年齢の確認がありません。公開プロフィールと投稿がある一般向けのSNSです。
- **リスク:** COPPAが適用されるのは、子ども向けのサービスか、利用者が13歳未満だと実際に知っている場合です。一般向けのサイトに年齢を調べる義務はありません。ただSNSには実際に子どもが来ます。年齢確認があれば、13歳未満と分かった相手のデータを集めずに済みます。制裁金は違反1件につき最大$53,088です。
- **修正:** 答えを誘導しない形で生年月と生年を聞く欄を足します。年齢はサーバー側で計算し、13歳未満ならアカウントを作らず、データも保存しません。

**── 2 · Google Fonts CDN (GDPR, EU) · RISK**
- **見つかったもの:** `app/layout.tsx:14-19` で、InterフォントをGoogleのサーバー（fonts.googleapis.com）から読み込んでいます。
- **リスク:** ドイツの裁判所（LG München I、2022年1月20日、3 O 17493/20）が、Googleにフォントを読み込ませたせいで訪問者のIPアドレスがGoogleに送られたとして、€100の支払いを命じた例があります。EUからの訪問者がいる場合に関係します。
- **修正:** `next/font/google` を使ってフォントを自サイトから配信する形に変え、CDNへのリンクはすべて削除します。

**── 3 · Session replay (CIPA) · RISK**
- **見つかったもの:** `app/providers.tsx:13-15` のPostHogは、同意なしで録画を始め、`maskAllInputs: false` で入力内容まで記録しています。
- **リスク:** カリフォルニア州の盗聴法（刑法§631、§637.2で違反1件$5,000）が、セッション録画ツールに対する訴訟で使われています。「1セッション$5,000」は原告側の主張で、確定した法解釈ではありません。
- **修正:** 入力のマスクを有効に戻し、同意を得てから録画を始めるようにします。プライバシーポリシーにも録画していることを書きます。

**── 4 · Marketing email (CAN-SPAM) · RISK**
- **見つかったもの:** `emails/launch-announcement.ts` のローンチ告知はクーポン付きの宣伝メールですが、配信停止リンクも住所もありません。
- **リスク:** CAN-SPAM（15 U.S.C. §7704）は、宣伝メールに機能する配信停止手段と有効な郵便住所を求めています。制裁金は1通につき最大$53,088です。
- **修正:** 署名付きの配信停止リンクと住所欄（TODO）をフッターに入れ、`/api/unsubscribe` を作ります。停止した人には送らず、List-Unsubscribeヘッダーも付けます。

**── 5 · Subscriptions (CA auto-renewal) · RISK**
- **見つかったもの:** `app/pricing/page.tsx:19` の「Go Pro」ボタンの近くに自動更新の条件がなく、同意のチェックもなく、オンラインで解約する方法もありません。
- **リスク:** カリフォルニア州の自動更新法（B&P §17602、AB 2863で改正）は、ボタンのすぐ近くに条件を表示すること、明示的な同意を取ること、オンラインで簡単に解約できることを求めています。
- **修正:** ボタンの横に条件の表示と同意チェックを追加し、Stripe Checkoutにも同じ文言を出します。解約はStripe Customer Portalに案内します。

**── 6 · User uploads (DMCA) · RISK**
- **見つかったもの:** `app/api/avatar/route.ts:11` で、アップロードされた画像を公開プロフィールに表示しています。DMCAのページはありません。
- **リスク:** DMCA §512(c)(2) のセーフハーバーを受けるには、指定代理人を米国著作権局に登録し（$6、3年ごとに更新）、その連絡先をサイトに載せる必要があります。
- **修正:** `/dmca` ページ（代理人の情報はTODO）を作り、フッターからリンクします。

**── 7 · Privacy policy & terms · RISK**
- **見つかったもの:** メール、名前、画像を集めていますが、`/privacy` も `/terms` もありません。
- **リスク:** カリフォルニア州のCalOPPAは、カリフォルニア州の住民から個人情報を集める商用サイトに、プライバシーポリシーを目立つ場所に載せることを求めています。利用規約は法的な義務ではありませんが、投稿や課金のルールを決めるものです。
- **修正:** コードの実態に合わせた2ページのドラフトを作り、全ページのフッターからリンクします。

**── 8 · Analytics consent · RISK**
- **見つかったもの:** `app/providers.tsx:9` で、PostHogがページを読み込んだ瞬間に動き始めます。同意を取る手順がありません。
- **リスク:** EUと英国では、必須でないCookieやトラッカーには事前の同意が要ります。米国の多くの州ではCookieバナーは必須ではありません。ただ、録画をめぐる盗聴法の訴訟（3）では、同意を得ていることが主な防御になります。
- **修正:** 同意バナーを追加し、「同意する」が押されてからPostHogを起動するようにします。「拒否」も同意と同じくらい押しやすくします。

**今すぐ適用できる修正:** 1–8
**人の手が必要なもの:** 実際の住所、DMCA代理人の登録、環境変数の設定、Stripe Portalの設定、弁護士のレビュー

Not legal advice — an automated check of 8 common traps, not a full legal review.

Apply the code fixes? (yes / no / only some numbers, e.g. "1 3")

## Turn 2

Wall time 158 s · cost $1.31 at API list prices · 32 tool calls

Now I'll apply the fixes. First 1 (age screen) and 2 (fonts).

Next: 3 and 8 (PostHog consent and masking).

Next: 4 (unsubscribe link and postal address in the launch email).

Next: 5 (renewal terms, consent checkbox, online cancel).

Next: 6 and 7 (the /dmca, /privacy and /terms pages).

Fixes are in. Now verifying: searching for leftovers, then typecheck and build.

8件すべてのコード修正を入れました。typecheck と build は両方通っています。

**Applied**
- ✓ 1: サインアップに生年月と生年の欄を追加しました。年齢はサーバー側で計算し、13歳未満ならアカウントを作らず、何も保存せず、24時間はブロック用のCookieを置きます。生年月日そのものは保存しません。変更したのは `app/signup/page.tsx` と `app/api/signup/route.ts` です。
- ✓ 2: Google FontsのCDNをやめて `next/font/google` に切り替えました。フォントは自サイトから配信されます。変更したのは `app/layout.tsx` と `app/globals.css` です。
- ✓ 3: `maskAllInputs: false` を削除して、PostHog標準の入力マスクに戻しました。録画していることはプライバシーポリシーに書いてあります。変更したのは `lib/analytics.ts` です。
- ✓ 4: 宣伝メールのフッターに、署名付きの配信停止リンクと住所欄（TODO）を入れました。
  - `/api/unsubscribe` を追加しています。GETは確認画面を出すだけで、POSTで実際に停止します。
  - List-Unsubscribeヘッダーを付け、停止した人には送らないようにしました。
  - `emails/`、`lib/unsubscribe.ts`、`lib/company.ts`、`lib/db.ts` を変更しています。
- ✓ 5: 「Go Pro」ボタンの横に更新条件（$12/月）と未チェックの同意ボックスを置きました。
  - 同意はサーバー側でも確認します。Stripe Checkoutにも同じ条件を表示します。
  - Customer Portalで管理・解約するボタンを追加しました（`app/api/billing-portal/route.ts`、`app/settings/profile/page.tsx`）。
- ✓ 6: `/dmca` ページを作り、フッターと利用規約からリンクしました。代理人の情報はTODOのままです。
- ✓ 7: `/privacy` と `/terms` のドラフトを作り、全ページのフッターからリンクしました。
- ✓ 8: 同意バナーを追加しました（`app/consent-banner.tsx`）。「同意する」が押されるまでPostHogは読み込まれず、「拒否」も同じ押しやすさです。

`.env.example` に新しい環境変数を2つ足しました：`UNSUBSCRIBE_SECRET` と `COMPANY_POSTAL_ADDRESS`。依存パッケージは追加していません。

**確認結果**
- 検索: ソースに `fonts.googleapis` / `fonts.gstatic` / `maskAllInputs` は残っていません。配信停止リンク、同意チェック、フッターのリンクがあることも確認しました。Grepツールが使えなかったので、`grep` で調べています。
- `npm run typecheck` → エラーなし
- `npm run build` → 成功（16ページ）
- lint用のスクリプトはないので、lintは実行していません。

**Human TODO（コードではできないこと）**
- [ ] メールのフッターに実際の郵便住所を入れる（CAN-SPAM）。
- [ ] ホスティング先に `UNSUBSCRIBE_SECRET` と `COMPANY_POSTAL_ADDRESS` を設定する。
- [ ] 宣伝メールの配信停止は10営業日以内に反映し、配信停止リンクは送信後30日以上使えるようにしておく。
- [ ] dmca.copyright.gov でDMCA代理人を登録し（$6、3年ごとに更新）、同じ情報を /dmca ページに書き写す。
- [ ] Stripe Customer Portalの設定で解約を有効にする。
- [ ] Stripeの顧客IDを保存する処理を作る。今は保存されていないので、「管理・解約」ボタンは404を返します。`checkout.session.completed` のWebhookで `session.customer` を保存してください。
- [ ] 更新条件に書いた価格（$12/月）を、Stripeの実際の価格と揃えておく。
- [ ] PostHogのダッシュボードで録画のマスク設定を確認する。
- [ ] 規約とポリシーのTODO（会社名、施行日、保存期間、準拠法、免責）を埋める。
- [ ] プライバシーポリシー、利用規約、更新条件、DMCAページを弁護士に確認してもらう。

Not legal advice. This checked 8 common traps with automated pattern matching and
may miss things. Have a lawyer review your policies and flows before you rely on them.
