class Urge < ApplicationRecord
  belongs_to :user
  belongs_to :alternative_action, optional: true

  enum :resolved, { pending: 0, calmed: 1, took_action: 2, viewed: 3 }, default: :pending
  enum :trigger, { idle: 0, working: 1 }

  def self.trigger_label(key)
    I18n.t("activerecord.attributes.urge/trigger.#{key}")
  end
end
