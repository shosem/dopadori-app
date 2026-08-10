FactoryBot.define do
  factory :user do
    # email は Devise の validatable で一意性が要求されるため、毎回ずらす。
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    name { "テスト" }
  end
end
