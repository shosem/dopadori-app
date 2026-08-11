require "rails_helper"

# 衝動記録はこのアプリの中核で、状態遷移(pending → calmed / took_action)が
# 画面をまたいで進む。モデル単体では「どの画面から来たか」を検証できないため、
# 遷移そのものと認可はここで守る。
RSpec.describe "Urges", type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }

  describe "未ログイン" do
    it "衝動ボタンの画面はログイン画面に飛ばされる" do
      get new_urge_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "記録を作成できない" do
      expect { post urges_path }.not_to change(Urge, :count)
    end
  end

  describe "ログイン済み" do
    before { sign_in user }

    describe "連打完了(create)" do
      # 連打を終えた時点で記録は確定させる。ここで作らずに入力画面まで待つと、
      # 入力せずに離脱した人の衝動が丸ごと消える。
      it "pending の記録が1件作られる" do
        expect { post urges_path }.to change(user.urges, :count).by(1)
        expect(user.urges.order(:id).last).to be_pending
      end

      it "入力画面へ遷移する" do
        post urges_path
        expect(response).to redirect_to(edit_urge_path(user.urges.order(:id).last))
      end
    end

    describe "入力画面(update)" do
      let(:urge) { create(:urge, user: user) }

      it "「落ち着いた」でトリガーとメモが保存され、calmed になる" do
        patch urge_path(urge),
              params: { next: "calmed", urge: { trigger: "idle", memo: "広告を見てしまって" } }

        urge.reload
        expect(urge.resolved).to eq("calmed")
        expect(urge.trigger).to eq("idle")
        expect(urge.memo).to eq("広告を見てしまって")
        expect(response).to redirect_to(root_path)
      end

      # 任意入力なので、空のまま送っても記録は成立する。
      it "トリガーを選ばなくても calmed にできる" do
        patch urge_path(urge), params: { next: "calmed", urge: { trigger: "", memo: "" } }

        expect(urge.reload.resolved).to eq("calmed")
        expect(urge.trigger).to be_nil
      end

      # 「代替行動を選ぶ」は宣言ではなく画面移動。実際に選ぶまでは took_action にしない。
      it "「代わりのことをする」ではメモだけ保存され、pending のまま提案画面へ進む" do
        patch urge_path(urge),
              params: { next: "suggestions", urge: { trigger: "working", memo: "作業に飽きて" } }

        urge.reload
        expect(urge.resolved).to eq("pending")
        expect(urge.memo).to eq("作業に飽きて")
        expect(response).to redirect_to(suggestions_urge_path(urge))
      end

      # viewed は「過去の結果」であり、このフローの選択肢として出さない(requirements.md 3章)。
      # resolved を許可していないので、送りつけられても遷移は変わらない。
      it "resolved を直接送りつけても viewed にはならない" do
        patch urge_path(urge),
              params: { next: "calmed", urge: { resolved: "viewed", memo: "" } }

        expect(urge.reload.resolved).to eq("calmed")
      end
    end

    describe "代替行動の提案(suggestions)" do
      let(:urge) { create(:urge, user: user) }

      # マザーデータ18件が3区分すべてに入っているので、初期状態で枠は欠けない。
      it "各 time_span から1件ずつ、計3件だけ提案される" do
        get suggestions_urge_path(urge)

        shown = user.alternative_actions.pluck(:title).count { |title| response.body.include?(title) }
        expect(shown).to eq(3)
      end

      # 空欄を見せると「登録して」という宿題を突きつけることになるため、枠ごと隠す。
      it "登録が0件の区分は提案されない" do
        user.alternative_actions.preparation.destroy_all

        get suggestions_urge_path(urge)

        shown = user.alternative_actions.pluck(:title).count { |title| response.body.include?(title) }
        expect(shown).to eq(2)
      end

      it "all を付けると自分の代替行動が全件出る" do
        get suggestions_urge_path(urge, all: 1)

        titles = user.alternative_actions.pluck(:title)
        shown = titles.count { |title| response.body.include?(title) }
        expect(shown).to eq(titles.size)
      end

      it "他人の代替行動は出ない" do
        create(:alternative_action, user: other, title: "他人の行動")

        get suggestions_urge_path(urge, all: 1)

        expect(response.body).not_to include("他人の行動")
      end
    end

    describe "代替行動の選択(took_action)" do
      let(:urge) { create(:urge, user: user) }
      let(:own_action) { create(:alternative_action, user: user, title: "自分の行動") }
      let(:other_action) { create(:alternative_action, user: other, title: "他人の行動") }

      it "選んだ代替行動が紐づき、took_action になる" do
        patch urge_path(urge), params: { alternative_action_id: own_action.id }

        urge.reload
        expect(urge.resolved).to eq("took_action")
        expect(urge.alternative_action).to eq(own_action)
        expect(response).to redirect_to(root_path)
      end

      # id を書き換えれば他人の行動を紐づけられる、という穴を塞ぐ。
      # current_user 経由で引いているかどうかにしか依存しない。
      it "他人の代替行動は選べない" do
        patch urge_path(urge), params: { alternative_action_id: other_action.id }

        expect(response).to have_http_status(:not_found)
        expect(urge.reload.alternative_action_id).to be_nil
        expect(urge.resolved).to eq("pending")
      end
    end

    describe "他人の記録" do
      let(:other_urge) { create(:urge, user: other) }

      it "入力画面を開けない" do
        get edit_urge_path(other_urge)
        expect(response).to have_http_status(:not_found)
      end

      it "更新できない" do
        patch urge_path(other_urge), params: { next: "calmed", urge: { memo: "乗っ取り" } }

        expect(response).to have_http_status(:not_found)
        expect(other_urge.reload.resolved).to eq("pending")
      end

      it "提案画面を開けない" do
        get suggestions_urge_path(other_urge)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
