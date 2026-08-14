FactoryBot.define do
  # 既定は「連打直後」の状態(resolved: pending / trigger も memo も無い)にしてある。
  # 衝動ボタンが実際に作るのはこの形なので、ここを既定にしないと spec が現実とずれる。
  factory :urge do
    user

    trait :calmed do
      resolved { :calmed }
    end

    # 代替行動は必ず同じ user のものにする。
    # 別々の user のものが紐づくと、認可の spec が意味を持たなくなる。
    trait :took_action do
      resolved { :took_action }
      alternative_action { association :alternative_action, user: user }
    end

    # resolved と直交するので、他の trait と重ねて使える(:took_action, :gave_in など)
    trait :gave_in do
      gave_in { true }
    end
  end
end
