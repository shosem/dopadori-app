class AlternativeAction < ApplicationRecord
  belongs_to :user
  enum :time_span, { immediate: 0, short: 1, preparation: 2 }
  validates :title, presence: true, length: { maximum: 30 }
  validates :time_span, presence: true, default: :immediate
end
