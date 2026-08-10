FactoryBot.define do
  # 注意: user を作ると after_create でマザーデータ18件が一緒に作られる。
  # 件数を検証する spec では、この18件を勘定に入れること。
  factory :alternative_action do
    user
    title { "深呼吸を3回" }
    time_span { :immediate }
  end
end
