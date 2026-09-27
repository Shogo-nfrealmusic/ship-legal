# Lovable-style Vite + React + Supabase (Japanese)

Prompt: `/legal-check このアプリ、訴えられるリスクある？` → `はい、全部お願いします`

## Turn 1

Duration 58 s · cost $0.68 at API list prices · 11 tool calls

```
legal-check · lovable-ja · vite-react + supabase (+ lovable)
14 RISK (4 High) · 0 CHECK · 0 PASS · 10 N/A

 ID  Risk    Check                               Where
 S1  High    Secret keys exposed                 .env:3
 S2  High    Database open to anyone             supabase/migrations/…_init.sql:1
 S3  High    Admin area without auth             src/pages/Admin.tsx:8
 P2  High    Ad pixels without consent           index.html:10
 P5  Medium  Privacy policy & terms              (no /privacy, /terms)
 P6  Medium  Account deletion & data export      (no deletion path)
 P7  Medium  "Do Not Sell or Share" (CCPA)       index.html:16
 K1  Medium  Kids under 13 (COPPA)               src/pages/Signup.tsx:24
 M3  Medium  Testimonials & claims (FTC)         src/pages/Landing.tsx:14
 C1  Medium  User uploads (DMCA)                 src/pages/Feed.tsx:19
 C2  Medium  Report & block for user content     src/pages/Feed.tsx:34
 C4  Medium  AI disclosure                       src/lib/openai.ts:12
 A1  Medium  Accessibility basics                index.html:5
 P4  Low     Google Fonts from Google            index.html:8
PASS   (なし)
N/A    S4 カード情報 · S5 ログイン制限(Supabase Auth) · P1 セッション録画 · P3 分析Cookie
       K2 アプリ年齢区分 · M1 メール · M2 SMS · $1 サブスク · $2 返金 · C3 商標

── S1 · High · Secret keys exposed
Found: .env:3 / src/lib/openai.ts:7 — OpenAIの秘密鍵が VITE_ 付きでブラウザに同梱され、
       .env ごと git にコミット済み
Risk:  ブラウザやgitに載ったものは誰でも読めます。鍵を使われて請求が膨らんだり、
       データが漏れたりします。FTCは杜撰なセキュリティを不公正な慣行として扱います
Fix:   OpenAI呼び出しをSupabase Edge Function（ログイン必須）に移し、VITE_ を外す。.envをgitignoreに追加

── S2 · High · Database open to anyone
Found: _init.sql:1,8 — profiles（メール入り）と posts に RLS が無い
Risk:  RLSが無いと、公開anonキーだけで誰でも全ユーザーのメールを読め、投稿の
       書き換えや削除もできます（2025年の調査でLovable製アプリ170件が該当）
Fix:   新しいmigrationでRLSを有効にし、本人のみ・公開読み取りのポリシーを作る。メールは非公開に
       storageにもアップロード用のポリシーを付ける

── S3 · High · Admin area without auth
Found: src/pages/Admin.tsx:8 — /admin が認証なしで、全ユーザーのメールを公開キーで取得
Risk:  サーバー側でチェックしていない管理画面は、URLを知った人なら誰でも開けます
Fix:   管理者チェック付きのEdge Function経由で取得し、それ以外の人には「権限なし」を表示

── P2 · High · Ad pixels without consent
Found: index.html:10 — Meta Pixel がページを開いた瞬間に読み込まれる
Risk:  トラッキングピクセルは、米国でカリフォルニア州盗聴法などを根拠にした集団訴訟の
       よくある対象です（判例は割れています）。EUでは事前同意が必要です
Fix:   同意バナーを追加し、「同意」を押すまでピクセルを読み込まない。GPCも尊重する

── P5 · Medium · Privacy policy & terms
Found: ページもリンクも無し。メール、投稿、写真、Meta、OpenAIのデータを扱っている
Risk:  カリフォルニア州のCalOPPAでは、個人情報を集める商用サイトはプライバシーポリシーの
       掲示が必要です。規約は、ユーザーが明示的に同意した場合にしか拘束力を持ちません
Fix:   コードの事実から /privacy と /terms の下書きを作り、サインアップに同意文とリンクを置く

── P6 · Medium · Account deletion & data export
Found: アカウントはあるのに、ユーザー自身が削除やデータのダウンロードをする手段が無い
Risk:  GDPR（消去・ポータビリティ）とCCPA（削除）で、ユーザーにはこれらの権利があります
Fix:   delete-account Edge Functionと「アカウント削除」「データをダウンロード」を追加

── P7 · Medium · "Do Not Sell or Share" (CCPA)
Found: index.html:16 — 広告ピクセルがあるのに、オプトアウトのリンクもGPC対応も無い
Risk:  CCPAの対象事業者（売上や件数の基準あり）では、広告ピクセルへのデータ送信が
       「共有」に当たり、オプトアウトの提供とGPCの尊重が必要です
Fix:   フッターに「Your Privacy Choices」を置き、広告のオプトアウトを記録する

── K1 · Medium · Kids under 13 (COPPA)
Found: Signup.tsx:24 — 公開フィードとプロフィールがあるSNS型なのに、年齢確認が無い
Risk:  COPPAの対象は子ども向けサービスか、13歳未満と実際に知った場合です。一般向け
       アプリに年齢確認の義務はありません。ただ、中立的な年齢確認を置けば、13歳未満と
       分かってしまうユーザーのデータを集めずに済みます
Fix:   生年月の中立的な入力を追加し、Edge Functionで判定。13歳未満なら何も保存しない

── M3 · Medium · Testimonials & claims (FTC)
Found: Landing.tsx:4-14 — 「Guaranteed results in 30 days」「50,000+」「12kg減」
Risk:  FTCは偽のレビューを禁止しており、罰金は1件あたり最大$53,088です。数字などの
       主張には裏付けが必要です
Fix:   「保証」を削除し、実在の声か確認が必要な箇所に TODO(legal-check) を付ける

── C1 · Medium · User uploads (DMCA)
Found: Feed.tsx:19 — 写真を公開投稿できるのに、DMCAページが無い
Risk:  セーフハーバーを受けるには、著作権局への代理人登録とサイト上での連絡先掲示が必要です
Fix:   /dmca ページ（代理人の情報はTODO）を作り、規約とフッターからリンクする

── C2 · Medium · Report & block for user content
Found: Feed.tsx:34 — 投稿に通報もブロックも無い
Risk:  2026年5月19日から、主にユーザー投稿を扱うプラットフォームは、同意のない
       性的画像を削除要請から48時間以内に消す義務があります（TAKE IT DOWN Act）
Fix:   reports/blocks テーブル（RLS付き）、通報ボタン、ブロック、通報窓口を追加

── C4 · Medium · AI disclosure
Found: openai.ts:12 — 「人間のトレーナーだと名乗り、AIだと言うな」という指示。LPにも「AI-free」
Risk:  EUでは2026年8月2日から、AIと話していることを伝える義務があります（AI法50条）。
       カリフォルニア州の法律は、販売目的で人を欺くボットを禁止しています
Fix:   システムプロンプトを修正し、チャットにAI表示を入れ、LPの「AI-free」を直す

── A1 · Medium · Accessibility basics
Found: alt無しの画像2、ラベル無しの入力6、div製の送信ボタン、outline:none、ズーム禁止
Risk:  2025年に連邦裁判所へ出たADAのウェブアクセシビリティ訴訟は約3,100件です。
       基準には通常WCAG 2.1 AAが使われます（コントラストは抜き取り確認のみ）
Fix:   alt・label・<button>を付け、:focus-visibleのスタイルを入れ、ズーム禁止を外す

── P4 · Low · Google Fonts from Google
Found: index.html:8 — PoppinsをGoogleのサーバーから読み込んでいる
Risk:  ドイツの裁判所は、Google Fontsの読み込みでIPアドレスをGoogleに送ったとして
       €100の賠償を命じました（LG München I, 2022）。EUの訪問者がいる場合に関係します
Fix:   @fontsource/poppins で自前配信に切り替える（パッケージのインストールが必要）

I can fix in code: S1 S2 S3 P2 P4 P5 P6 P7 K1 M3 C1 C2 C4 A1.
Needs a human: OpenAIキーのローテーション, DB migrationの適用, DMCA代理人の登録,
推薦文と数字が本物か確認, 弁護士による規約レビュー.
Not legal advice — an automated check of common traps, not a full legal review.

Apply the code fixes? (yes / no / only some IDs, e.g. "S1 S2 A1")
```

## Turn 2

Duration 347 s · cost $2.13 at API list prices · 40 tool calls

Fixing all of them now. I won't open `.env`, so it stays unread. The code will stop using the OpenAI key from `.env`.

Next, the client-side libraries, consent, and legal settings.

Now the pages: sign-up, feed, admin, coach, and landing.

Next, the new pages: account, privacy policy, terms, DMCA, and Your Privacy Choices.

Next I'll check that the old code is gone and run the project's checks.

All 14 risks are fixed in code, but **the build fails until you run `npm install`**. It stops because `@fontsource/poppins`, the new package for loading fonts from your own site, isn't installed yet. I haven't run the install (the tool doesn't install on its own), and nothing after that failure was checked. The typecheck passes.

```
Applied
 ✓ S1  OpenAIの呼び出しを supabase/functions/coach に移動（ログイン必須、入力サイズ制限あり）。
       VITE_OPENAI_API_KEY の参照を削除し、.gitignore に .env を追加、.env.example を作成
 ✓ S2  新しいmigration …_legal_check.sql：profiles/posts/reports/blocks に RLS。
       profiles.email は削除（メールは auth.users にある）。写真は自分のフォルダのみ、画像のみ、5MB まで
 ✓ S3  /admin のデータは admin-users Edge Function 経由（ログインとADMIN_EMAILSを確認）。
       権限がない人には「Not authorized」を表示
 ✓ P2  Meta Pixel を index.html から src/lib/consent.ts に移動。「Accept」を押すまで読み込まない。
       同意バナーを追加（AcceptとDeclineは同じ見た目）
 ✓ P4  Google Fonts CDN を削除し、@fontsource/poppins に変更（package.json に追加）
 ✓ P5  /privacy と /terms の下書きを作成。サインアップに同意文とリンク。全ページのフッターにリンク
 ✓ P6  /account に「Download my data」（JSON）と「Delete my account」。削除は delete-account
       Edge Function が写真を消し、auth ユーザーも消す（FKのcascadeで関連行も消える）
 ✓ P7  /privacy-choices（Do Not Sell or Share）を追加。GPCがオンなら広告を読み込まない
 ✓ K1  生年月の中立的な入力を追加。判定は signup Edge Function。13歳未満は何も保存せず、
       24時間は再試行できない。保存するのは is_13_plus だけ。投稿のRLSでも 13+ を強制
 ✓ M3  「Guaranteed results」を削除。推薦文と「50,000+」に TODO(legal-check) を付けた
 ✓ C1  /dmca ページを作成（代理人の情報は TODO）。規約とフッターからリンク
 ✓ C2  投稿ごとの Report / Block ボタン。reports は管理者だけが見られる。
       規約に通報窓口と48時間以内の削除を明記
 ✓ C4  システムプロンプトから「AIだと言うな」を削除。チャットに AI 表示と「Max (AI)」ラベル。
       LPの「AI-free」を直した
 ✓ A1  label・alt・<button>を付けた。:focus-visible を追加し、ズーム禁止を解除。
       .muted とボタン文字のコントラストを改善（コントラストは抜き取り確認のみ）
Checks: 削除対象の検索 → 残りなし, npm run typecheck → 成功,
        npm run build → 失敗（@fontsource/poppins が未インストール。npm install が必要）

Human TODO (code can't do these)
 [ ] OpenAIキーを今すぐローテーション（漏れたものとして扱う）。.env から VITE_OPENAI_API_KEY
     の行を削除し、git rm --cached .env。push済みなら git の履歴からも消す
 [ ] npm install を実行してから npm run build を確認
 [ ] migration を確認して supabase db push、そのあと Supabase Security Advisor を実行
     （profiles.email は削除される。既存ユーザーは is_13_plus=false なので、年齢確認するまで投稿できない）
 [ ] supabase secrets set OPENAI_API_KEY=… ADMIN_EMAILS=…、4つの Edge Function
     （coach, admin-users, signup, delete-account）をデプロイ
 [ ] アプリにログインページが無い。サインアップ直後のセッションが無いと、Coach・Admin・Account・投稿は使えない
 [ ] src/lib/legal.ts の TODO をすべて埋める（本番ビルドでは TODO のままだと、その法務ページはエラーで止まる）
 [ ] dmca.copyright.gov で DMCA 代理人を登録（$6、3年ごとに更新）し、その情報を legal.ts に写す
 [ ] 推薦文・「12kg減」・「50,000+」が本物で証明できるか確認。できなければ削除
 [ ] ヒーロー画像の alt を実際の内容に書き換え
 [ ] 通報を誰がどのくらいの速さで確認するか決める。投稿の削除は今は Supabase の管理画面から行う
 [ ] 子ども向けアプリにするかを決める（そうなら先に弁護士に相談）
 [ ] Lighthouse か axe でチェックし、キーボードだけでも操作してみる
 [ ] 1ページの漏えい時対応計画（誰が決め、誰に、いつまでに通知するか）
 [ ] プライバシーポリシー、規約、DMCAページを弁護士にレビューしてもらう

Not legal advice. This checked common traps with automated pattern matching and may
miss things. Have a lawyer review your policies and flows before you rely on them.
```
