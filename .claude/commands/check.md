---
description: ローカルの状態を点検し、ブラウザでの確認手順を提示する
---

1. !`docker compose ps`
2. 落ちていれば `docker compose up -d` で起動する
3. !`docker compose logs --tail=40 web`
   例外・エラーがあれば、**開発者に触らせる前に**原因と直し方を報告して先に潰す。
4. `git diff main --stat` を見て、いま確認すべき画面を特定する
5. 次の形式で出力する:
   - **URL**: http://localhost:3200/...
   - **操作**: 1) ... 2) ...
   - **期待**: 画面に「...」が出る / 出ない
   - **DB確認**: `docker compose exec web bin/rails runner "..."` (期待する出力も書く)
6. 手順を出したら**停止し、開発者の確認結果を待つ**。自分で「動いているはず」と結論しない。
