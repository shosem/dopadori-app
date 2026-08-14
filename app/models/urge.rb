class Urge < ApplicationRecord
  RECENT_DAYS = 7

  belongs_to :user
  belongs_to :alternative_action, optional: true

  # 「我慢できなかった」はここには入れない。resolved は衝動ボタンのフローの結果、
  # gave_in はその後どうなったかで、軸が違う(両方同時に成り立つ)。
  enum :resolved, { pending: 0, calmed: 1, took_action: 2 }, default: :pending
  enum :trigger, { idle: 0, working: 1 }

  scope :recent, ->(days = RECENT_DAYS) {
    from = (Time.zone.today - (days - 1)).beginning_of_day
    where(created_at: from..).order(created_at: :desc)
  }

  def self.daily_counts(days = RECENT_DAYS)
    dates = ((Time.zone.today - (days - 1))..Time.zone.today).to_a

    counts = recent(days).group_by { |urge| urge.created_at.in_time_zone.to_date }.transform_values(&:size)

    dates.map { |date| { date: date, count: counts.fetch(date, 0) } }
  end

  # 「あとから記録する」画面の日付入力。列ではなく、created_at をどの日に置くかの入力。
  # created_at を直接フォームに出さないのは、時刻まで送り込めるようにしないため。
  attr_accessor :occurred_on

  # 日付だけ指定された時に created_at をどこに置くか。
  # 時刻は聞かない(本人も覚えていない上に、入力を増やすと記録しなくなる)ので、
  # 「その日の、いま押した時刻」に置く。押した時刻は実在の値なので、
  # 00:00 や 12:00 を作って一覧に出すより嘘が小さい。
  #
  # Time.zone を通さずに組み立てると、コンテナのシステムタイムゾーン(UTC)で
  # 解釈される。夜遅い時刻ほど危険で、22:00 を UTC として保存すると
  # JST では翌日の 07:00 になり、棒グラフとストリークが1日ぶん静かに前へずれる。
  def self.occurred_at(date_string, now = Time.zone.now)
    date = Date.parse(date_string.to_s)
    Time.zone.local(date.year, date.month, date.day, now.hour, now.min, now.sec)
  rescue Date::Error
    now
  end

  def self.trigger_label(key)
    I18n.t("activerecord.attributes.urge/trigger.#{key}")
  end

  def self.resolved_label(key)
    I18n.t("activerecord.attributes.urge/resolved.#{key}")
  end

  def self.current_streak
    urge_dates = pluck(:created_at).map { |time| time.in_time_zone.to_date }.to_set

    # 今日はまだ終わっていないので、記録が無くても連続を切らずに昨日から数える
    # (日付が変わった直後に 0 を見せないため。requirements.md 7章)
    today = Time.zone.today
    start_date = urge_dates.include?(today) ? today : today - 1

    count = 0
    date = start_date

    while urge_dates.include?(date)
      count += 1
      date -= 1
    end

    count
  end
end
