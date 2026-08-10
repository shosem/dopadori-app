class AlternativeAction < ApplicationRecord
  belongs_to :user
  enum :time_span, { immediate: 0, short: 1, preparation: 2 }, default: :immediate
  validates :title, presence: true, length: { maximum: 30 }
  validates :time_span, presence: true
end
