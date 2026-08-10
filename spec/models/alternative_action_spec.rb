require "rails_helper"

RSpec.describe AlternativeAction, type: :model do
  describe "title のバリデーション" do
    it "空だと無効" do
      expect(build(:alternative_action, title: "")).to be_invalid
    end

    it "30文字ちょうどなら有効" do
      expect(build(:alternative_action, title: "あ" * 30)).to be_valid
    end

    it "31文字だと無効" do
      expect(build(:alternative_action, title: "あ" * 31)).to be_invalid
    end
  end

  describe "time_span" do
    # 整数との対応を変えると、保存済みレコードの区分が黙ってずれる。
    # ここを固定しておくことで、うっかり並べ替えた時に気づける。
    it "3つの区分が定義された整数に対応している" do
      expect(described_class.time_spans)
        .to eq({ "immediate" => 0, "short" => 1, "preparation" => 2 })
    end

    it "未指定なら immediate になる" do
      expect(described_class.new.time_span).to eq("immediate")
    end

    it "明示的に nil を入れると無効" do
      expect(build(:alternative_action, time_span: nil)).to be_invalid
    end

    it "区分ごとのスコープで絞り込める" do
      action = create(:alternative_action, time_span: :preparation)
      actions = action.user.alternative_actions

      expect(actions.preparation).to include(action)
      expect(actions.immediate).not_to include(action)
    end
  end

  describe "user との関連" do
    it "user が無いと無効" do
      expect(build(:alternative_action, user: nil)).to be_invalid
    end
  end
end
