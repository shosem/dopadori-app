require "rails_helper"

# root から authenticate_user! を外して、未ログインなら説明画面を出すようにした。
# 「未ログインでも開ける」と「ログイン済みには自分の画面が出る」の両方が
# 同時に成り立たないと、どちらかに倒れて気づけない。
#
# 判定に使う文字列は、宣伝文ではなく各画面の固定要素にする。
# 見出しの言い回しは何度も変わるので、そこに紐づけると spec が言葉の都合で落ちる。
RSpec.describe "Tops", type: :request do
  describe "未ログイン" do
    # ここが「URLを渡された初見の人」の最初の1枚になる。
    # ログイン画面に飛ばしていた頃は、何のアプリか一言も説明が無かった。
    it "ログイン画面へ飛ばさず、説明画面を出す" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("使い方")
      expect(response.body).not_to include("おかえりなさい")
    end

    # 説明画面は current_user を触らない。触ると未ログインで落ちる。
    # 衝動フローはログインが要るので、ここから直接は入れない。
    it "衝動ボタンへの導線は出さない" do
      get root_path

      expect(response.body).not_to include(new_urge_path)
    end
  end

  describe "ログイン済み" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "説明画面ではなく自分の画面が出る" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("おかえりなさい")
      expect(response.body).not_to include("使い方")
    end

    # 記録が無い人には、その人が持っている代替行動が1つ出る(tops#top)。
    # ここが動いていれば current_user 側の分岐が生きている。
    it "記録が無ければ自分の代替行動が1つ出る" do
      create(:alternative_action, user: user, title: "この行動が出るはず")

      get root_path

      expect(response.body).to include("衝動が来たら、たとえば")
    end
  end
end
