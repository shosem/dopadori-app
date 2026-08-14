class TopsController < ApplicationController
  before_action :authenticate_user!

  def top
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
