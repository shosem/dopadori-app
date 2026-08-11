class User < ApplicationRecord
  MOTHER_ACTIONS = [

    { title: "手をぎゅっと握って開く", time_span: :immediate },
    { title: "拍手を10回思いきり", time_span: :immediate },
    { title: "その場で10回ジャンプする", time_span: :immediate },
    { title: "冷たい水で顔を洗う", time_span: :immediate },
    { title: "部屋の中を1周歩く", time_span: :immediate },
    { title: "声に出して数を10まで数える", time_span: :immediate },
    { title: "腕立て10回", time_span: :short },
    { title: "腹筋10回", time_span: :short },
    { title: "スクワット10回", time_span: :short },
    { title: "5分歩く", time_span: :short },
    { title: "ストレッチをする", time_span: :short },
    { title: "シャワーを浴びる", time_span: :short },
    { title: "コンビニで好きなお菓子を1つ買う", time_span: :short },
    { title: "ジムで筋トレする", time_span: :preparation },
    { title: "サウナに行く", time_span: :preparation },
    { title: "30分ランニングする", time_span: :preparation },
    { title: "外に散歩・買い物に出る", time_span: :preparation },
    { title: "友達に連絡を取る", time_span: :preparation }

  ].freeze

  devise :database_authenticatable, :rememberable, :registerable, :validatable
  validates :name, presence: true, length: { maximum: 10 }
  has_many :alternative_actions, dependent: :destroy
  has_many :urges, dependent: :destroy
  after_create :distribute_mother_actions

  private

  def distribute_mother_actions
    MOTHER_ACTIONS.each { |attrs| self.alternative_actions.create!(attrs) }
  end
end
