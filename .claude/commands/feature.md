---
description: 機能スライスを開始する(docs読込 → スコープ合意 → ブランチ作成 → 縦に実装)
argument-hint: <機能名 例: urge-flow>
---

# 機能スライス開始: $1

## 手順(この順で実行する)

1. 以下を**実際に読み直す**(記憶で書かない)
   - @CLAUDE.md
   - @docs/requirements.md
   - @docs/design_guideline.md
2. 現在の状態を確認する
   - !`git branch --show-current`
   - !`git status --short`
3. **実装せず、まずスコープを日本語5行以内で提示して停止する。**
   - 作る画面 / 触るテーブル / 追加するルート
   - 今回やらないこと(意図的に切るもの)
   - 開発者がブラウザで確認する手順
   承認前にファイルを1つも書き換えない。
4. 承認後 `git switch -c feature/$1`(main のままなら必ず切る)
5. **縦に貫通させる**。順序:
   migration → model(enum / association / validation) → routes → controller
   → view(ERB + Tailwind v4) → Stimulus(必要な場合のみ、index.js への登録を忘れない)
   UIだけ・モデルだけで止めない。
6. `docker compose exec web bin/rails db:migrate`
7. `docker compose exec web bin/rubocop -a`
8. 最後に「ブラウザ確認手順」を番号付きで出力する(URL / 入力値 / 期待表示)

## 制約
- 思想に関わる判断を勝手にしない。迷ったら docs を優先し、質問する。
- 絵文字を使わない。連打回数・スコアを表示しない。責める文言を書かない。
- CLAUDE.md §9 の技術ルール(Tailwind v4 / Rails 8.1 enum / docker exec 経由)を守る。
