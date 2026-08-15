require "rails_helper"

# ログイン不要で衝動ボタンだけ体験してもらう画面。
# URLを渡された初見の人に、登録の前に何をするアプリか分かってもらうのが目的。
RSpec.describe "Trials", type: :request do
  describe "未ログイン" do
    it "お試し画面を開ける" do
      get try_path

      expect(response).to have_http_status(:ok)
    end

    it "結果画面を開ける" do
      get try_result_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("落ち着きましたか")
    end

    # ここが一番守りたい性質。お試しは記録を作らない。
    # Urge は belongs_to :user なのでゲストには作れず、作らないと決めたことで
    # 既存の衝動フローに一切手を入れずに済んでいる。
    it "記録が1件も作られない" do
      expect {
        get try_path
        get try_result_path
      }.not_to change(Urge, :count)
    end

    # 36秒の完了時に Stimulus が requestSubmit() する送り先。
    # ここが本番と同じ /urges になっていると、ゲストがログイン画面に飛ばされて
    # 体験が途切れる(そして記録も作られない)。
    it "36秒の送り先が結果画面になっている" do
      get try_path

      expect(response.body).to include("action=\"#{try_result_path}\"")
      expect(response.body).not_to include("action=\"#{urges_path}\"")
    end
  end

  describe "ログイン済み" do
    let(:user) { create(:user) }

    before { sign_in user }

    # 本番の衝動ボタン画面と同じパーシャルを使っているので、
    # 送り先が入れ替わっていないことを両方向で見る。
    it "本番の衝動ボタン画面は urges#create へ送る" do
      get new_urge_path

      expect(response.body).to include("action=\"#{urges_path}\"")
      expect(response.body).not_to include("action=\"#{try_result_path}\"")
    end

    it "ログイン済みでもお試し画面は開ける" do
      get try_path

      expect(response).to have_http_status(:ok)
    end
  end
end
