require "rails_helper"

# このスペックの主目的は認可の確認。
# 「他人の代替行動を編集・削除できないこと」はモデルのバリデーションでは守れず、
# コントローラが current_user から引いているかどうかにしか依存しないため、
# ここで落とせないと URL の id を書き換えるだけで破れる。
RSpec.describe "AlternativeActions", type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }

  # マザーデータ18件は全ユーザーが同じタイトルを持つので、
  # 本文で持ち主を判定できるよう、判別できるタイトルを付ける。
  let(:own_action) { create(:alternative_action, user: user, title: "自分の行動") }
  let(:other_action) { create(:alternative_action, user: other, title: "他人の行動") }

  describe "未ログイン" do
    it "一覧はログイン画面に飛ばされる" do
      get alternative_actions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "作成できない" do
      expect {
        post alternative_actions_path,
             params: { alternative_action: { title: "未ログインの行動", time_span: :immediate } }
      }.not_to change(AlternativeAction, :count)
    end

    it "削除できない" do
      own_action
      expect {
        delete alternative_action_path(own_action)
      }.not_to change(AlternativeAction, :count)
    end
  end

  describe "ログイン済み" do
    before { sign_in user }

    describe "自分の代替行動" do
      it "一覧に出る" do
        own_action
        get alternative_actions_path
        expect(response.body).to include("自分の行動")
      end

      it "編集画面が開ける" do
        get edit_alternative_action_path(own_action)
        expect(response).to have_http_status(:ok)
      end

      it "更新できる" do
        patch alternative_action_path(own_action),
              params: { alternative_action: { title: "変更後", time_span: :short } }
        expect(own_action.reload.title).to eq("変更後")
      end

      it "削除できる" do
        own_action
        expect {
          delete alternative_action_path(own_action)
        }.to change(AlternativeAction, :count).by(-1)
      end
    end

    describe "他人の代替行動" do
      it "一覧に出ない" do
        other_action
        get alternative_actions_path
        expect(response.body).not_to include("他人の行動")
      end

      it "編集画面を開けない" do
        get edit_alternative_action_path(other_action)
        expect(response).to have_http_status(:not_found)
      end

      it "更新できない" do
        expect {
          patch alternative_action_path(other_action),
                params: { alternative_action: { title: "乗っ取り", time_span: :short } }
        }.not_to change { other_action.reload.title }
        expect(response).to have_http_status(:not_found)
      end

      it "削除できない" do
        other_action
        expect {
          delete alternative_action_path(other_action)
        }.not_to change(AlternativeAction, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "作成" do
      it "自分のものとして作られる" do
        post alternative_actions_path,
             params: { alternative_action: { title: "新しい行動", time_span: :short } }
        expect(AlternativeAction.find_by(title: "新しい行動").user).to eq(user)
      end

      # user_id は許可していないので、送られてきても無視される。
      # ここが破れると、他人名義のレコードを作られる。
      it "user_id を送りつけても他人のものにはならない" do
        post alternative_actions_path,
             params: { alternative_action: { title: "偽装した行動", time_span: :short, user_id: other.id } }
        expect(AlternativeAction.find_by(title: "偽装した行動").user).to eq(user)
      end
    end
  end
end
