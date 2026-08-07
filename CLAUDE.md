# CLAUDE.md

> このファイルは Claude Code が毎セッションで参照する「指示書」です。
> 詳細な設計・経緯は `docs/` に置いてあります。ここには「コードを書くたびに参照すること」と
> 「守るべき規約・禁止事項」だけを書きます。背景や"なぜ作るか"は docs を読んでください。

---

## 1. プロジェクト概要

「ドパドリ(dopadori-app)」は、SNS・ポルノ・タバコなどへの衝動を、**我慢させるのではなく代替行動で発散させる**Webアプリ。
衝動が来たら「衝動ボタン」を押し、連打しながら3-3-6呼吸で発散する。その後、落ち着いたか／代替行動を選ぶかを記録する。
コンセプトは「悪い刺激は0秒で来る。だから代替行動も0秒で始められるように用意しておく」。

- 詳細な企画・思想: `docs/app_concept.md`
- 要件・DB設計: `docs/requirements.md`
- デザイン方針: `docs/design_guideline.md`
- 開発スケジュール: `docs/dev_schedule.md`

**重要**: 判断に迷ったら、まず上記 docs を読むこと。このアプリは「設計思想の一貫性」が命なので、思想に関わる判断を勝手にしない。

---

## 2. 技術スタック(バージョン厳守)

- Ruby 3.4
- Rails 8.1.3.1(8.1.3 系。セキュリティパッチは取り込む)
- PostgreSQL(開発: Docker内 / 本番: Neon)
- Tailwind CSS(**Node経由**: cssbundling-rails)
- Hotwire(Turbo / Stimulus)
- 認証: Devise
- デプロイ: Web = Render / DB = Neon
- Docker(Dockerfile.dev, compose.yml)

古いRailsの書き方(Rails 6/7時代の記法)を使わないこと。Rails 8.1 の作法に従う。

### Turbo の使い分け(この方針を外れないこと)
- **Turbo Drive**: デフォルト有効。大半の画面遷移はこれで足りる。特別な対応不要。
- **Turbo Frames**: **代替行動の登録・削除まわりでのみ**部分導入する。
- **Turbo Streams**: **使わない**(今回の規模ではオーバースペック)。
- **衝動ボタンのアニメーション**: Turbo ではなく **Stimulus + カスタムCSS**。サーバー通信しない。

---

## 3. データモデル(要点のみ / 詳細は docs/requirements.md)

3テーブル: `users` / `alternative_actions` / `urges`

### enum の値(コードで頻繁に使うので直書き)
- `alternative_actions.time_span`: `immediate`(即できる) / `short`(少し時間がかかる) / `preparation`(準備がいる)
- `urges.resolved`: `pending`(デフォルト・連打直後) / `calmed`(落ち着いた) / `took_action`(代替行動へ) / `viewed`(見てしまった)
- `urges.trigger`: `idle`(暇なとき) / `working`(作業中) ※ null許容・任意

### 重要な設計判断(コードに影響するので厳守)
- **urge は衝動ボタン(連打)完了時に1件作成する**(resolved: pending)。その後の入力で同じレコードを更新する。「衝動が来た事実を取りこぼさない」が最優先。
- **`viewed` は衝動ボタンのフロー内の選択肢として出さない**。必ずトップの別入口から記録する(過去の結果と未来の宣言を混ぜない)。
- **マザーデータ(代替行動の初期セット)は、ユーザー登録時に各ユーザー用にコピーして配る**(user_id を全レコードが持つ。共有データにしない)。マザーデータの具体的な中身は docs/requirements.md 参照。
- 代替行動は「全部表示」しない。衝動時は **各 time_span から1つずつランダム提案**し、immediate を主役にする。登録0件の time_span 枠は非表示。

---

## 4. コーディング規約

- テーブル名・カラム名・enum値は `docs/requirements.md` の定義に厳密に従う。勝手に変えない。
- Stimulus コントローラは1つの責務に集中させる(衝動ボタンのタイマー/アニメーション制御など)。
- Tailwind で表現しきれないアニメーション(呼吸する円の膨張・収縮・鼓動)は、カスタムCSS(@keyframes)で書く。どこに書くかは実装時に統一する。
- コメントは「なぜそうするか」を書く。「何をしているか」はコードで分かるので不要。
- 日本語のUI文言は、デザイン方針(docs/design_guideline.md)のトーンに従う(優しく・責めない・絵文字なし)。

### テスト
- 本線に入れるのは **rspec-rails + factory_bot_rails のみ**。model spec を機能ごとに数本書く。
- システムスペック(Capybara + Selenium)は**バッファ日(08/13以降)の目標**。6日間の本線には入れない。理由は `docs/dev_schedule.md` の「テスト方針」を参照。
- テスト用DBの分離は **`config/database.yml` の test セクションで `TEST_DATABASE_URL` を参照させて初めて成立する**(Rails に `TEST_DATABASE_URL` という規約はない)。分離できているかは推測せず、必ず実測で確認する:
  `docker compose exec web bin/rails runner -e test 'puts ActiveRecord::Base.connection_db_config.database'`

---

## 5. やってはいけないこと(このアプリの思想に直結)

- **衝動ボタンの連打で、回数・スコアを表示しない**。数値を見せると「新しい依存・ゲーム化」を生むため。あくまで発散(サンドバッグ)であって、達成ではない。
- **過剰な感覚フィードバックを付けない**(強い振動・派手な音・派手なアニメーション)。フィードバック自体が新しい刺激・依存になるため。
- **「見てしまった」記録や、ストリークが途切れた時に、責めるUI・文言を作らない**。「記録しました」「また今日から」と淡々と・優しく。赤字の警告や派手なリセット演出は禁止。
- **ストリークの最高記録を表示しない**(ハードル・プレッシャーになるため)。今続いている連続日数のみ。
- **絵文字を使わない**(ちらつき・軽薄さを避ける)。温かさは色・丸み・言葉で出す。
- 衝動時の画面に、余計な入力や選択を増やさない(急いで発散したい人を邪魔しない)。任意入力は小さく、スキップが自然に見えるように。

---

## 6. 環境・コマンド

- 起動: `docker compose up`(Web は http://localhost:3200 で確認)
- コンテナ内でコマンドを実行する: `docker compose exec web bash` に入るか、`docker compose exec web <command>`
- ポート: Web=3200 / DB=ホスト側5434(コンテナ内5432) / Chrome=4446
- DB接続は Docker 内部ネットワーク経由(ホスト名 `db`、ポート5432)。`.env` の DATABASE_URL / TEST_DATABASE_URL を参照。
- マイグレーション: `docker compose exec web rails db:migrate`
- テスト実行: `docker compose exec web rspec`(または bundle exec rspec)

---

## 7. 開発の進め方(docs/dev_schedule.md の要点)

- **提出 2026/08/17。完成目標 08/12。08/13〜08/16 はバッファ。**日次計画は `docs/dev_schedule.md` を参照(2026/08/07 に旧4週間計画から全面改訂済み。**「第1週」等の週単位の記述は無効**)。
- バッファは薄い。**時間を溶かしやすいものは後回し**にする。
- 「衝動ボタンの呼吸アニメーション」は Day 6 に作り込む(180分タイムボックス)。先に地味でも動くアプリを完成させる。
- **Turbo Frames は Day 6 までは一切入れない。**通常のページ遷移で機能は成立する。
- 「動かないカッコいいもの」より「動く地味なもの」を優先。
- 迷ったら、機能を増やす方向ではなく、確実に動かす方向に倒す。
- 死守する4機能: **認証 / 代替行動CRUD / 衝動記録 / 棒グラフ**。削る順序は `docs/dev_schedule.md` のリカバリー方針に従う。
- **Day 1〜6 は日付ではなく順序**。意味のある関門は1つだけ:「死守4機能 + ストリークが本番で動く = 発表できる状態」。
- **前倒しできた時に上積み(Turbo Frames・アニメーション作り込み)を提案しない。**上の関門に到達するまで、余った時間は次のコア機能に使う。切ったものは「溶けやすいから切った」もの。

---

## 8. Git運用ルール

### ブランチ
- 命名規則: feature/<機能名>, fix/<内容>（例: feature/post-crud, fix/login-redirect）
- 粒度: 1ブランチ = 1機能（縦に貫通させた単位）。UIだけ、モデルだけの分割はしない
- 作業開始時は必ず `git checkout -b` で新規ブランチを切ってから着手する
- mainには直接コミットしない

### コミット
- 1コミット = 意味のある1単位（動く状態を保つ）
- メッセージは日本語 or Conventional Commits形式（feat:, fix:, refactor:）どちらでもいいので統一する
- コミット前に必ず動作確認したことを前提とする

### マージ
- 機能が動作確認済みになったら、私に「マージしていいか」を確認してから作業を進める
- 自動でmainにマージしない
- **マージ = 本番デプロイ**(Render が main への push で自動デプロイする)。`git merge` と `git push` は開発者本人が実行する。

---

## 9. 実装時の技術的な必須ルール(毎回ここを間違える)

### コマンド実行
- ホストに Ruby / Rails / node_modules の実行環境はない。**すべて `docker compose exec web ...` 経由**。裸の `bin/rails` `rspec` `yarn` を実行しない。
- **1回の Bash 呼び出しでコマンドを `&&` で連結しない**。許可リストは連結された各セグメントを個別に照合するため、許可済みコマンドでも毎回確認ダイアログが出る。
- **`yarn add` は必ずコンテナ内で実行する**。node_modules は bind mount されており、ネイティブバイナリ(`@tailwindcss/oxide`, `esbuild`)は **linux-arm64 用**が入っている。ホスト(macOS)で `yarn add` すると darwin 用に入れ替わり、コンテナのビルドが壊れる。

### Tailwind
- **v4**(cssbundling-rails + `@tailwindcss/cli`)。**`tailwind.config.js` を作らない**(v4では不要かつ混乱の元)。
- 設定もデザイントークンも `app/assets/stylesheets/application.tailwind.css` に書く。`@source` でスキャン対象を明示し、`@theme` でトークンを定義する。呼吸アニメーションの `@keyframes` も同ファイル末尾に置く(§4「どこに書くかは実装時に統一する」への回答)。
- v4 でリネームされたクラスを v3 の名前で書かない:
  `shadow` → `shadow-sm` / `shadow-sm` → `shadow-xs` / `rounded-sm` → `rounded-xs` / `outline-none` → `outline-hidden` / `flex-shrink-0` → `shrink-0` / `bg-opacity-50` → `bg-black/50`

### Rails 8.1
- enum は**位置引数形式のみ**。キーワード形式(`enum resolved: {...}`)は Rails 8 で削除済み。
  正: `enum :resolved, { pending: 0, calmed: 1, took_action: 2, viewed: 3 }, default: :pending`
- enum のデフォルトは**モデルの `default:` だけに頼らず、マイグレーションにも `default: 0, null: false` を書く**(seed や `insert_all` を通った時に pending にならない事故を防ぐ)。
- `config.time_zone = "Tokyo"` が前提。**日付の集計・比較は必ず `in_time_zone` を通す**。UTC のまま `to_date` すると朝の記録が前日扱いになり、棒グラフとストリークが静かに壊れる。
- 日別集計は SQL の `GROUP BY DATE(...)` ではなく **Ruby 側で `in_time_zone.to_date` してグルーピングする**(タイムゾーン指定を間違えても動いてしまうため)。
- 本番では solid_cache / solid_queue / solid_cable を使わない(DB は Neon 1本)。

### カラム名 `trigger` について
`urges.trigger` はこのままでよい。PostgreSQL では `TRIGGER` は非予約語でカラム名に使え、ActiveRecord は識別子を常にクォートする。`ActiveRecord::Base` に `trigger` は定義されていないので `DangerousAttributeError` にもならない。**親切心でリネームを提案しない。**

### Hotwire
- **Stimulus コントローラを追加したら `app/javascript/controllers/index.js` に手動で import + register する**(または `bin/rails stimulus:manifest:update`)。このリポジトリは自動 eager load していない。忘れると「エラーも出ず、何も起きない」状態になる。
- Chart.js を Stimulus で使う場合、`disconnect()` で `chart.destroy()` を必ず呼ぶ。Turbo Drive のキャッシュ復元で canvas が再利用され "Canvas is already in use" になる。
- データの受け渡しは Stimulus values を使う。ERB 内に `<script>` で JSON を埋めると CSP に引っかかる。
- DELETE リンクは `data: { turbo_method: :delete }`。`method: :delete`(Rails 6記法)は Turbo 下で GET になり動かない。
- Turbo Streams は使わない。Turbo Frames は代替行動まわりのみ、かつバッファ日に回す。

---

## 10. 作業分担(2026/08/07 決定。以降のセッションでも維持する)

これはイベントに提出するアプリであり、発表で説明を求められ、数ヶ月後に本人が読み返すコードである。
**目的は開発速度ではなく、本人が作って説明できること。**この前提で分担を決めている。

### 誰が書くか

| 領域 | 書く | 検証 |
|---|---|---|
| **アプリコード**(モデル / コントローラ / ビュー / Stimulus / ルーティング) | **開発者本人** | 本人 |
| **設定・環境**(Tailwind設定 / database.yml / Docker / Procfile / デプロイ / gem導入) | Claude | **Claude が実測で検証** |
| **思想が絡むもの**(UI文言 / 衝動ボタンの仕様 / 画面の情報量) | **開発者本人** | 本人 |

**Claude はアプリコードを勝手に書かない。**求められているのは、実装方針・ハマりどころ・
設計上の選択肢の提示と、書かれたコードのレビュー、そして詰まった時の救出である。
コードを書くのは、下記「30分ルール」が発動した時か、明示的に依頼された時だけ。

### 30分ルール(バッファを守る唯一の仕組み)

開発者が詰まって**30分進まなかったら、その部分は Claude が書く**。
本人はそのコードを読んで理解する。**自力で解くことより、動くものを提出することを優先する。**
提出日は 2026/08/17 で、バッファは有限である。

### ペース(ここを外すとレビューが成立しない)

- **設定を書く時は、書く前に「何をなぜ変えるか」を伝えて一度止まる。**
  複数ファイルをまとめて変更して事後報告しない。レビューできない速度は、速度ではない。
- アプリコードの方針を渡す時は、**コードではなく方針とハマりどころを渡す**。
  雛形として数行示すのはよいが、丸ごと書いて渡さない。
- 1スライスごとに止まってブラウザ確認を挟む(`.claude/commands/` の feature / check / wrap)。

### 検証の原則

**静かに壊れるもの(DB接続 / 日付集計 / タイムゾーン / デプロイ設定)は、推測で「大丈夫」と言わない。**
必ずコマンドを実行して実測する。実例: `TEST_DATABASE_URL` は「分離済み」と文書に書かれていたが
実際には分離されておらず、テスト実行時に開発DBを破壊しうる状態だった(§4 の検証コマンドを参照)。