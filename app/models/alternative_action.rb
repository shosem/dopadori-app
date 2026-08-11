class AlternativeAction < ApplicationRecord
  belongs_to :user
  has_many :urges, dependent: :nullify
  enum :time_span, { immediate: 0, short: 1, preparation: 2 }, default: :immediate
  validates :title, presence: true, length: { maximum: 30 }
  validates :time_span, presence: true

  def self.time_span_label(key)
    I18n.t("activerecord.attributes.alternative_action/time_span.#{key}")
  end

  def time_span_label
    self.class.time_span_label(time_span)
  end

  def self.time_span_options
    time_spans.keys.map { |key| [I18n.t("activerecord.attributes.alternative_action/time_span.#{key}"), key] }
  end
end
