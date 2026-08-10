require "rails_helper"

RSpec.describe User, type: :model do
  describe "name のバリデーション" do
    it "空だと無効" do
      expect(build(:user, name: "")).to be_invalid
    end

    it "10文字ちょうどなら有効" do
      expect(build(:user, name: "あ" * 10)).to be_valid
    end

    it "11文字だと無効" do
      expect(build(:user, name: "あ" * 11)).to be_invalid
    end

    # name はログインIDではなく表示名なので、重複を許す。
    # unique 索引が付いていると保存時に例外になり、フォームではなく500になる。
    it "同じ name の2人目も登録できる" do
      create(:user, name: "同名")
      expect(build(:user, name: "同名")).to be_valid
    end
  end

  describe "マザーデータの配布" do
    it "作成すると18件が配られる" do
      user = create(:user)
      expect(user.alternative_actions.count).to eq(18)
    end

    it "time_span の内訳が docs/requirements.md 2-2-2 と一致する" do
      user = create(:user)
      expect(user.alternative_actions.group(:time_span).count)
        .to eq({ "immediate" => 6, "short" => 7, "preparation" => 5 })
    end

    it "配られた行動は本人に紐づく" do
      user = create(:user)
      expect(user.alternative_actions.pluck(:user_id).uniq).to eq([ user.id ])
    end

    it "別のユーザーの行動は混ざらない" do
      user = create(:user)
      other = create(:user)
      expect(user.alternative_actions & other.alternative_actions).to be_empty
    end

    # title の上限を縮めると after_create が例外を投げ、
    # 「新規登録が丸ごと失敗する」という形で壊れる。最長は16文字。
    it "MOTHER_ACTIONS の全件が AlternativeAction のバリデーションを通る" do
      owner = build(:user)
      invalid = User::MOTHER_ACTIONS.reject do |attrs|
        AlternativeAction.new(attrs.merge(user: owner)).valid?
      end
      expect(invalid).to be_empty
    end
  end

  describe "削除" do
    it "ユーザーを消すと代替行動も一緒に消える" do
      user = create(:user)
      expect { user.destroy }.to change(AlternativeAction, :count).by(-18)
    end
  end
end
