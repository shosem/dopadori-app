require "rails_helper"

RSpec.describe Urge, type: :model do
  describe "resolved" do
    # 整数との対応を変えると、保存済みレコードの状態が黙ってずれる。
    # ここを固定しておくことで、うっかり並べ替えた時に気づける。
    it "4つの状態が定義された整数に対応している" do
      expect(described_class.resolveds)
        .to eq({ "pending" => 0, "calmed" => 1, "took_action" => 2, "viewed" => 3 })
    end

    it "未指定なら pending になる" do
      expect(described_class.new.resolved).to eq("pending")
    end

    # 「衝動が来た事実を取りこぼさない」ため、連打完了時は他の入力なしで1件作れる必要がある。
    it "user だけで保存できる" do
      expect(build(:urge)).to be_valid
    end

    # モデルの default: を通らない経路(insert_all / seed)でも pending であること。
    # ここが崩れると resolved が nil のレコードが生まれ、集計から静かに漏れる。
    it "モデルを経由しない挿入でも pending になる" do
      user = create(:user)
      now = Time.current
      described_class.insert_all([ { user_id: user.id, created_at: now, updated_at: now } ])

      expect(described_class.order(:id).last.resolved).to eq("pending")
    end

    it "状態ごとのスコープで絞り込める" do
      calmed = create(:urge, :calmed)
      pending = create(:urge, user: calmed.user)

      expect(described_class.calmed).to include(calmed)
      expect(described_class.calmed).not_to include(pending)
    end
  end

  describe "trigger" do
    it "2つの区分が定義された整数に対応している" do
      expect(described_class.triggers).to eq({ "idle" => 0, "working" => 1 })
    end

    # 任意項目。選ばずに次へ進めることが要件(スキップ用の余計なタップを増やさない)。
    it "未選択のまま保存できる" do
      urge = create(:urge)
      expect(urge.trigger).to be_nil
    end

    # 入力画面の select は include_blank を使うため、空文字が送られてくる。
    # ここが例外になると「スキップして進む」が壊れる。
    it "空文字を渡すと nil になる" do
      urge = create(:urge, trigger: "")
      expect(urge.trigger).to be_nil
    end
  end

  describe "alternative_action との関連" do
    it "紐づいていなくても保存できる" do
      expect(build(:urge, alternative_action: nil)).to be_valid
    end

    it "took_action では選んだ代替行動が紐づく" do
      urge = create(:urge, :took_action)

      expect(urge.resolved).to eq("took_action")
      expect(urge.alternative_action).to be_present
    end

    # ユーザーは「膝が悪いから筋トレを消す」ことができる(requirements.md 2-2)。
    # その時、過去に選んだ記録まで消えると棒グラフが後から書き換わってしまうので、
    # 記録は残して参照だけ外す(DB側 on_delete: :nullify と dependent: :nullify)。
    it "選んだ代替行動を削除しても、記録は残って参照だけ外れる" do
      urge = create(:urge, :took_action)

      expect { urge.alternative_action.destroy! }
        .not_to change(described_class, :count)

      expect(urge.reload.alternative_action_id).to be_nil
      expect(urge.resolved).to eq("took_action")
    end
  end

  describe "user との関連" do
    it "user が無いと無効" do
      expect(build(:urge, user: nil)).to be_invalid
    end

    it "user を削除すると一緒に消える" do
      urge = create(:urge)

      expect { urge.user.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
