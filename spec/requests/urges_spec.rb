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

    it "あとからの記録も作成できない" do
      expect { post gave_in_urges_path, params: { urge: { occurred_on: Time.zone.today.to_s, memo: "" } } }
        .not_to change(Urge, :count)
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

      # 状態はコントローラが決める。urge_params が resolved も gave_in も許可していないので、
      # このフローに送りつけても通らない。「我慢できなかった」は専用の入口からだけ立つ。
      it "resolved を直接送りつけても無視される" do
        patch urge_path(urge),
              params: { next: "calmed", urge: { resolved: "took_action", memo: "" } }

        expect(urge.reload.resolved).to eq("calmed")
      end

      it "gave_in を直接送りつけても立たない" do
        patch urge_path(urge),
              params: { next: "calmed", urge: { gave_in: true, memo: "" } }

        expect(urge.reload.gave_in).to be(false)
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

    describe "記録の詳細(show)" do
      it "自分の記録を開ける" do
        urge = create(:urge, :calmed, user: user, memo: "通知が来て気になった")

        get urge_path(urge)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("通知が来て気になった")
      end

      # took_action + gave_in は両立する。ここで代替行動が消えると、
      # gave_in を boolean にした理由(起きたことを消さない)が画面側で崩れる。
      it "代わりのことをした上で我慢できなかった記録は、選んだ行動も出る" do
        action = create(:alternative_action, user: user, title: "散歩に行く")
        urge = create(:urge, :gave_in, user: user, resolved: :took_action, alternative_action: action)

        get urge_path(urge)

        expect(response.body).to include("散歩に行く")
      end
    end

    describe "我慢できなかったの付け外し(gave_in)" do
      let(:urge) { create(:urge, :calmed, user: user) }

      it "立てられる" do
        patch gave_in_urge_path(urge), params: { urge: { gave_in: "1" } }

        expect(urge.reload.gave_in).to be(true)
        expect(response).to redirect_to(urge_path(urge))
        expect(flash[:notice]).to eq("我慢できなかった記録をつけました")
      end

      # チェックボックスは外した時に hidden の "0" が飛ぶ。ここが通らないと
      # 「一度つけたら戻せない」になり、確認ダイアログを外した判断が成立しない。
      it "外せる" do
        urge.update!(gave_in: true)

        patch gave_in_urge_path(urge), params: { urge: { gave_in: "0" } }

        expect(urge.reload.gave_in).to be(false)
        expect(flash[:notice]).to eq("取り消しました")
      end

      # flash を body 直下に置いていた時、fixed なヘッダーの裏に潜って見えないまま
      # main だけが押し下げられていた。redirect_to の戻り値だけ見ても気づけないので、
      # 遷移先まで追って、main の中に描かれていることを確かめる。
      it "遷移先で flash が main の中に描かれる" do
        patch gave_in_urge_path(urge), params: { urge: { gave_in: "1" } }
        follow_redirect!

        expect(response.body).to include("我慢できなかった記録をつけました")
        expect(response.body.index("<main")).to be < response.body.index("我慢できなかった記録をつけました")
      end

      # resolved は別の軸なので、付け外ししても動かない。
      it "resolved は変わらない" do
        patch gave_in_urge_path(urge), params: { urge: { gave_in: "1" } }

        expect(urge.reload.resolved).to eq("calmed")
      end

      # gave_in_params は :gave_in しか許可していないので、相乗りは効かない。
      it "同じリクエストで memo を書き換えられない" do
        urge.update!(memo: "もとのメモ")

        patch gave_in_urge_path(urge), params: { urge: { gave_in: "1", memo: "上書き" } }

        expect(urge.reload.memo).to eq("もとのメモ")
      end
    end

    # 衝動ボタンを押す間もなく直行した分を、あとから記録する経路(requirements.md 5章 B)。
    describe "あとから記録する(new_gave_in / create_gave_in)" do
      let(:today) { Time.zone.today.to_s }

      it "入力画面が開ける" do
        get gave_in_urges_path

        expect(response).to have_http_status(:ok)
      end

      it "gave_in が立った記録が1件作られる" do
        expect { post gave_in_urges_path, params: { urge: { occurred_on: today, memo: "" } } }
          .to change(user.urges, :count).by(1)

        expect(user.urges.order(:id).last.gave_in).to be(true)
      end

      # 3-3-6 を通っていないので、記録すべき「結果」が存在しない。
      # ここで calmed などを入れると、やっていないことを記録することになる。
      it "resolved は pending のまま" do
        post gave_in_urges_path, params: { urge: { occurred_on: today, memo: "" } }

        expect(user.urges.order(:id).last).to be_pending
      end

      it "メモも一緒に保存できる" do
        post gave_in_urges_path, params: { urge: { occurred_on: today, memo: "広告を見てしまって" } }

        expect(user.urges.order(:id).last.memo).to eq("広告を見てしまって")
      end

      it "作った記録の詳細へ飛ぶ" do
        post gave_in_urges_path, params: { urge: { occurred_on: today, memo: "" } }

        expect(response).to redirect_to(urge_path(user.urges.order(:id).last))
        expect(flash[:notice]).to eq("記録しました")
      end

      # 遡って記録した分は、その日の棒として立つ。今日に寄せてしまうと
      # 「昨日の衝動が今日に記録される」ことになり、振り返りが実態とずれる。
      it "遡った日付を指定すると、その日の記録として入る" do
        travel_to(Time.zone.parse("2026-08-14 09:30")) do
          post gave_in_urges_path, params: { urge: { occurred_on: "2026-08-11", memo: "" } }

          expect(user.urges.order(:id).last.created_at.in_time_zone.to_date)
            .to eq(Date.new(2026, 8, 11))
        end
      end

      # 未来の記録は棒グラフの窓にもストリークにも入らず、どこからも見えなくなる。
      # form の max はブラウザ任せなので、サーバ側で弾けていることを見る。
      it "未来の日付では作られない" do
        travel_to(Time.zone.parse("2026-08-14 09:30")) do
          expect { post gave_in_urges_path, params: { urge: { occurred_on: "2026-08-15", memo: "" } } }
            .not_to change(user.urges, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      # 棒グラフとストリークは created_at だけを見るので、この経路の記録も同じように数える。
      # ここが数えられないと、正直に記録した日だけ棒が立たない画面になる。
      it "その日の集計に入る" do
        post gave_in_urges_path, params: { urge: { occurred_on: today, memo: "" } }

        expect(user.urges.daily_counts.last[:count]).to eq(1)
      end
    end

    describe "他人の記録" do
      let(:other_urge) { create(:urge, user: other) }

      it "詳細を開けない" do
        get urge_path(other_urge)
        expect(response).to have_http_status(:not_found)
      end

      it "我慢できなかったを立てられない" do
        patch gave_in_urge_path(other_urge), params: { urge: { gave_in: "1" } }

        expect(response).to have_http_status(:not_found)
        expect(other_urge.reload.gave_in).to be(false)
      end

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
