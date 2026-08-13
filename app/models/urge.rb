class Urge < ApplicationRecord
  RECENT_DAYS = 7

  belongs_to :user
  belongs_to :alternative_action, optional: true

  enum :resolved, { pending: 0, calmed: 1, took_action: 2, viewed: 3 }, default: :pending
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

  def self.trigger_label(key)
    I18n.t("activerecord.attributes.urge/trigger.#{key}")
  end

  def self.resolved_label(key)
    I18n.t("activerecord.attributes.urge/resolved.#{key}")
  end
end
