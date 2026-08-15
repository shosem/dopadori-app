class TopsController < ApplicationController
  # authenticate_user! は掛けない。未ログインで開いた人に説明を出すため。
  # ここが「URLを渡された初見の人」が最初に見る画面になる。
  def top
    return render :landing unless user_signed_in?

    urges = current_user.urges

    @streak = urges.current_streak
    @daily_counts = urges.daily_counts
    @has_records = @daily_counts.any? { |day| day[:count].positive? }

    # 記録が無い間だけ、その人の代替行動を1つ見せる。
    # マザーデータ18件を最初から持っていることに気づかないまま終わるのを防ぐ。
    # 全部消したユーザーは nil になるので、ビュー側で出し分ける。
    @suggested_action = current_user.alternative_actions.sample unless @has_records
  end
end
