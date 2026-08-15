# ログイン不要で、衝動ボタンだけ体験してもらう画面。
# authenticate_user! は掛けない。URLを渡された初見の人に、
# 登録の前に「何をするアプリか」を体で分かってもらうのが目的。
#
# 記録は一切作らない。Urge は belongs_to :user なのでゲストには作れないし、
# 作らないと決めたことで、既存の衝動フローに一切手を入れずに済んでいる。
class TrialsController < ApplicationController
  def new; end

  def result; end
end
