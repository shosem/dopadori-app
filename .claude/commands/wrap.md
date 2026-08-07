---
description: 機能スライスを締める(lint → 差分要約 → コミット → マージ可否を確認)
argument-hint: <コミットメッセージ 例: feat: 衝動ボタンと衝動記録>
---

1. !`docker compose exec web bin/rubocop -a`
2. !`git status --short`
3. !`git diff --stat`
4. 変更内容を日本語3〜5行で要約する(**何を・なぜ**)
5. **残っている懸念を正直に列挙する**(仮実装・TODO・未使用コード・未検証の分岐)。
   問題がなければ「なし」と書く。取り繕わない。
6. `git add -A` → `git commit -m "$ARGUMENTS"`
7. **必ずここで停止し、次を出力する:**

   > ブラウザでの動作確認は取れていますか?
   > OK なら、ご自身で以下を実行してください:
   > `git switch main && git merge --no-ff <branch> && git push`
   > (push で Render に自動デプロイされます)

   **自分でマージ・push はしない**(CLAUDE.md §8)。
