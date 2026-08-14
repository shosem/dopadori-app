require "rails_helper"

RSpec.describe Urge, type: :model do
  describe "resolved" do
    # 整数との対応を変えると、保存済みレコードの状態が黙ってずれる。
    # ここを固定しておくことで、うっかり並べ替えた時に気づける。
    it "3つの状態が定義された整数に対応している" do
      expect(described_class.resolveds)
        .to eq({ "pending" => 0, "calmed" => 1, "took_action" => 2 })
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

  describe "gave_in" do
    # false は「まだ何も言っていない」であって「我慢できた」ではない。
    # true を既定にすると、全レコードがアプリの知らない成功を主張することになる。
    it "既定では false" do
      expect(described_class.new.gave_in).to be(false)
    end

    # モデルの default: を通らない経路(insert_all / seed)でも false であること。
    # nil が混ざると、一覧の分岐が黙って「印なし」に倒れる。
    it "モデルを経由しない挿入でも false になる" do
      user = create(:user)
      now = Time.current
      described_class.insert_all([ { user_id: user.id, created_at: now, updated_at: now } ])

      expect(described_class.order(:id).last.gave_in).to be(false)
    end

    # gave_in を enum ではなく独立した列にした理由そのもの。
    # 排他にすると、我慢できなかったに変えた時点で「代替行動をやった」事実が消える。
    it "resolved と同時に成り立ち、選んだ代替行動も消えない" do
      urge = create(:urge, :took_action, :gave_in)

      expect(urge.resolved).to eq("took_action")
      expect(urge.gave_in).to be(true)
      expect(urge.alternative_action).to be_present
    end

    it "落ち着いた記録にも後から立てられる" do
      urge = create(:urge, :calmed)

      urge.update!(gave_in: true)

      expect(urge.reload.resolved).to eq("calmed")
      expect(urge.gave_in).to be(true)
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

  describe "RECENT_DAYS" do
    # 記録ページの「直近何日ぶんか」を決める唯一の場所。
    # ここが1箇所に閉じていれば、あとから1ヶ月表示を足す時にコントローラの引数だけで済む。
    it "既定の集計期間は7日" do
      expect(described_class::RECENT_DAYS).to eq(7)
    end
  end

  # 期間の境界は「ずれても画面は普通に表示される」種類のバグなので、
  # 目視では見つからない。ここで固定する。
  describe ".recent" do
    let(:user) { create(:user) }

    around do |example|
      travel_to(Time.zone.parse("2026-08-12 12:00")) { example.run }
    end

    it "期間の下端(6日前の0時)ちょうどの記録を含む" do
      urge = create(:urge, user: user, created_at: Time.zone.parse("2026-08-06 00:00:00"))

      expect(user.urges.recent).to include(urge)
    end

    it "下端の1秒前の記録は含まない" do
      urge = create(:urge, user: user, created_at: Time.zone.parse("2026-08-05 23:59:59"))

      expect(user.urges.recent).not_to include(urge)
    end

    # 記録一覧は新しいものから読む画面なので、並び順もこのメソッドの責務に含める。
    it "新しい順に並ぶ" do
      older = create(:urge, user: user, created_at: Time.zone.parse("2026-08-10 09:00"))
      newer = create(:urge, user: user, created_at: Time.zone.parse("2026-08-12 09:00"))

      expect(user.urges.recent.to_a).to eq([ newer, older ])
    end

    it "日数を渡すと期間が変わる" do
      urge = create(:urge, user: user, created_at: Time.zone.parse("2026-07-20 09:00"))

      expect(user.urges.recent).not_to include(urge)
      expect(user.urges.recent(30)).to include(urge)
    end

    it "他のユーザーの記録は含まない" do
      other_users_urge = create(:urge, created_at: Time.zone.parse("2026-08-12 09:00"))

      expect(user.urges.recent).not_to include(other_users_urge)
    end
  end

  describe ".daily_counts" do
    let(:user) { create(:user) }

    subject(:counts) { user.urges.daily_counts }

    context "日中に見たとき(2026-08-12 12:00 JST)" do
      around do |example|
        travel_to(Time.zone.parse("2026-08-12 12:00")) { example.run }
      end

      it "RECENT_DAYS 日ぶんを、古い順に、末尾が今日で返す" do
        expect(counts.size).to eq(described_class::RECENT_DAYS)
        expect(counts.first[:date]).to eq(Date.new(2026, 8, 6))
        expect(counts.last[:date]).to eq(Date.new(2026, 8, 12))
      end

      # 記録が無い日の棒を消すと「その日が存在しない」ように見えてしまうため、
      # 0 の日も要素として残す(モック確定時の決定)。
      it "記録が1件も無くても、全ての日が 0 で埋まる" do
        expect(counts.map { |day| day[:count] }).to eq([ 0 ] * described_class::RECENT_DAYS)
      end

      # daily_counts が recent を土台にしていれば自動的に通る。
      # 別々に期間を計算していると、ここが片方だけずれる。
      it "期間外の記録は数えない" do
        create(:urge, user: user, created_at: Time.zone.parse("2026-08-05 23:59:59"))

        expect(counts.sum { |day| day[:count] }).to eq(0)
      end

      it "同じ日の複数件をまとめて数える" do
        [ "10:00", "13:00", "22:00" ].each do |time|
          create(:urge, user: user, created_at: Time.zone.parse("2026-08-09 #{time}"))
        end

        expect(counts.find { |day| day[:date] == Date.new(2026, 8, 9) }[:count]).to eq(3)
      end

      # 本命。UTC のまま日付に落とすと 8/11 に数えられ、棒グラフが静かに1日ずれる。
      it "日付が変わった直後(JST 00:15)の記録が、当日に入る" do
        create(:urge, user: user, created_at: Time.zone.parse("2026-08-12 00:15"))

        expect(counts.last).to eq({ date: Date.new(2026, 8, 12), count: 1 })
      end

      # グラフは「衝動が来た回数」。どう終わったかで数を変えない。
      # ここで gave_in を除くと、正直に記録した人だけ棒が減る画面になる。
      it "resolved の状態と gave_in を問わず数える" do
        create(:urge, user: user, created_at: Time.zone.parse("2026-08-12 08:00"))
        create(:urge, :calmed, user: user, created_at: Time.zone.parse("2026-08-12 09:00"))
        create(:urge, :took_action, user: user, created_at: Time.zone.parse("2026-08-12 10:00"))
        create(:urge, :gave_in, user: user, created_at: Time.zone.parse("2026-08-12 11:00"))

        expect(counts.last[:count]).to eq(4)
      end

      it "他のユーザーの記録を数えない" do
        create(:urge, created_at: Time.zone.parse("2026-08-12 09:00"))

        expect(counts.sum { |day| day[:count] }).to eq(0)
      end

      it "日数を渡すと要素数が変わる" do
        expect(user.urges.daily_counts(30).size).to eq(30)
      end
    end

    context "日付が変わる直前に見たとき(2026-08-12 23:59:59 JST)" do
      around do |example|
        travel_to(Time.zone.parse("2026-08-12 23:59:59")) { example.run }
      end

      # 00:15 と逆側の境界。ここを翌日に数えると、寝る前の記録が明日の棒になる。
      it "23:59 の記録が、翌日ではなく当日に入る" do
        create(:urge, user: user, created_at: Time.zone.parse("2026-08-12 23:59:30"))

        expect(counts.last).to eq({ date: Date.new(2026, 8, 12), count: 1 })
      end
    end
  end

  # 算出ルールは requirements.md 7章。resolved を問わず全件を数え、
  # 今日の記録が無ければ昨日を起点にする。最高記録は持たない。
  describe ".current_streak" do
    let(:user) { create(:user) }

    subject(:streak) { user.urges.current_streak }

    # 日付だけが問題なので時刻は固定でよい。境界を見る spec だけ時刻を明示する。
    def urge_on(owner, date, time = "10:00", **attrs)
      create(:urge, **attrs, user: owner, created_at: Time.zone.parse("#{date} #{time}"))
    end

    context "2026-08-13(木) 12:00 JST に見たとき" do
      around do |example|
        travel_to(Time.zone.parse("2026-08-13 12:00")) { example.run }
      end

      it "記録が1件も無ければ 0" do
        expect(streak).to eq(0)
      end

      it "今日だけ記録があれば 1" do
        urge_on(user, "2026-08-13")

        expect(streak).to eq(1)
      end

      it "今日と昨日にあれば 2" do
        urge_on(user, "2026-08-13")
        urge_on(user, "2026-08-12")

        expect(streak).to eq(2)
      end

      # 今日を「未確定」として扱う。日付が変わった直後に 0 を見せないため。
      it "今日が無く、昨日まで3日続いていれば 3" do
        [ "2026-08-12", "2026-08-11", "2026-08-10" ].each { |date| urge_on(user, date) }

        expect(streak).to eq(3)
      end

      it "今日も昨日も無ければ 0" do
        urge_on(user, "2026-08-11")
        urge_on(user, "2026-08-10")

        expect(streak).to eq(0)
      end

      it "同じ日に何件あっても 1日として数える" do
        [ "08:00", "15:00", "23:00" ].each { |time| urge_on(user, "2026-08-13", time) }

        expect(streak).to eq(1)
      end

      it "間に空いた日があれば、そこで止まる" do
        urge_on(user, "2026-08-13")
        urge_on(user, "2026-08-12")
        urge_on(user, "2026-08-10")

        expect(streak).to eq(2)
      end

      # 「我慢できなかった」を正直に記録した日が連続から外れると、記録そのものが罰になる。
      it "gave_in だけの日も数える" do
        urge_on(user, "2026-08-13", gave_in: true)
        urge_on(user, "2026-08-12", gave_in: true)

        expect(streak).to eq(2)
      end

      it "他のユーザーの記録は数えない" do
        urge_on(create(:user), "2026-08-13")

        expect(streak).to eq(0)
      end

      # UTC のまま日付に落とすと、今日 00:15 の記録が昨日(8/12)扱いになる。
      # すると今日が空になって昨日起点に切り替わり、8/11 まで繋がって 2 を返してしまう。
      it "今日 00:15 の記録は今日として数える(昨日が空なら 1 で止まる)" do
        urge_on(user, "2026-08-13", "00:15")
        urge_on(user, "2026-08-11")

        expect(streak).to eq(1)
      end

      # ストリークは棒グラフの期間(RECENT_DAYS)に縛られない。
      it "7日を超えても数え続ける" do
        (0..9).each { |n| urge_on(user, (Time.zone.today - n).to_s) }

        expect(streak).to eq(10)
      end
    end

    context "月初(2026-08-01) に見たとき" do
      around do |example|
        travel_to(Time.zone.parse("2026-08-01 12:00")) { example.run }
      end

      it "月をまたいでも連続する" do
        [ "2026-08-01", "2026-07-31", "2026-07-30" ].each { |date| urge_on(user, date) }

        expect(streak).to eq(3)
      end
    end
  end
end
