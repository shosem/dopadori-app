# デモ用のダミーデータ。
#
# db/seeds.rb に書かない理由: seeds は db:setup や db:prepare(新規DB作成時)で
# 自動的に走る。デモデータが意図しないタイミングで入るのを避けたいので、
# 明示的に叩く rake タスクにしてある。
#
#   docker compose exec web bin/rails demo:seed
#
# lib/tasks/*.rake は Rails が自動で読み込むので、登録作業は要らない。

namespace :demo do
  # desc を書くと bin/rails -T の一覧に出る。書かないと隠しタスクになる。
  desc "開発用のデモアカウントと、直近14日ぶんの衝動記録を作り直す"

  # task の引数に環境を渡さないと、User も Urge も未定義でコケる。
  # rake タスクは既定では Rails アプリを読み込まないため。
  task seed: :environment do
    # 本番のデータを触る事故を防ぐ。デモアカウントは dev にしか作らない判断(2026/08/14)。
    unless Rails.env.development?
      abort "demo:seed は development でのみ実行できます(現在: #{Rails.env})"
    end

    EMAIL = "demo@example.com"
    PASSWORD = "demodemo"

    # 何日前に何件か。減っていく物語は作らない。後半にも山を置く。
    #
    # 6日前を 0 にしているのは、棒グラフ(直近7日)の左端に「記録が無い日の線」を
    # 出しつつ、ストリークを最大まで伸ばすため。グラフの中にゼロの日を置くと
    # そこでストリークが切れるので、左端が両立できる唯一の位置になる。
    COUNTS = {
      13 => 3, 12 => 5, 11 => 1, 10 => 0, 9 => 4, 8 => 2, 7 => 6,
      6 => 0,  5 => 3,  4 => 1,  3 => 5,  2 => 2, 1 => 4, 0 => 2
    }.freeze

    # 衝動が来る時刻は夜に寄せる。昼と朝も少し混ぜる。
    HOURS = [ 22, 23, 21, 0, 1, 22, 23, 20, 12, 13, 15, 8, 23, 21 ].freeze

    MEMOS = [
      "通知が来て気になった",
      "作業が行き詰まった",
      "寝る前にだらだら見そうになった",
      "広告が目に入って",
      "朝いちで開きそうになった",
      "人と話したあとで落ち着かない",
      "やることが終わって手が空いた"
    ].freeze

    # 乱数のシードを固定する。状態・メモ・代替行動の選ばれ方が毎回同じになるので、
    # 「さっき見た画面」と違うものが出る事故を避けられる。
    # ただし日時は実行時刻からの相対で作るため、そこだけは実行のたびに動く。
    rng = Random.new(20260814)

    user = User.find_or_initialize_by(email: EMAIL)

    if user.new_record?
      user.name = "デモ"
      user.password = PASSWORD
      user.save!
      puts "デモアカウントを作成: #{EMAIL} / #{PASSWORD}"
    else
      puts "既存のデモアカウントを使用: #{EMAIL}"
    end

    # 何度叩いても増殖しないように、このユーザーの記録だけ消してから作り直す。
    # 代替行動(マザーデータ18件)は User の after_create で配られるので触らない。
    removed = user.urges.destroy_all.size
    puts "既存の記録を削除: #{removed}件" if removed.positive?

    actions = user.alternative_actions.to_a

    COUNTS.each do |days_ago, count|
      count.times do |i|
        # 日付の計算は必ず Time.zone を通す。UTC のまま組み立てると、
        # 深夜の記録が前日に寄って棒グラフとストリークが静かに1日ずれる。
        at = Time.zone.now.beginning_of_day - days_ago.days
        at += HOURS[(days_ago + i) % HOURS.size].hours + rng.rand(60).minutes

        # 今日ぶんだけは、すでに過ぎた時間帯に配り直す。
        # 時刻プールが夜に寄っているので、そのまま使うと未来の時刻になって全部捨てられ、
        # 棒グラフの右端(今日)が空になる。実際にそうなった。
        if days_ago.zero?
          today = Time.zone.now.beginning_of_day
          at = today + ((Time.zone.now - today) * (i + 1) / (count + 1))
        end

        # 保険。未来の記録は棒グラフの窓にもストリークにも入らず、どこからも見えなくなる。
        next if at > Time.zone.now

        # 落ち着いた 5 / 代わりのことをした 3 / 記録のみ 2 くらいの配合。
        # 記録のみ(pending)が一定数あるのが実態で、ここを 0 にすると
        # 「全員がちゃんと入力を終える」前提の、きれいすぎる一覧になる。
        resolved = [ :calmed ] * 5 + [ :took_action ] * 3 + [ :pending ] * 2
        resolved = resolved.sample(random: rng)

        user.urges.create!(
          created_at: at,
          resolved: resolved,
          alternative_action: (actions.sample(random: rng) if resolved == :took_action),
          trigger: [ nil, nil, :idle, :working ].sample(random: rng),
          # メモは3割くらいにだけ付ける。任意入力は普通スキップされるのが実態。
          memo: (MEMOS.sample(random: rng) if rng.rand < 0.3),
          gave_in: rng.rand < 0.2
        )
      end
    end

    # 「代わりのことをした上で、それでも我慢できなかった」を必ず1件は用意する。
    # gave_in を resolved の4つ目にせず独立した列にした理由そのものなので、
    # 発表でこの組み合わせを見せられる状態にしておく(requirements.md 3章)。
    both = user.urges.where(resolved: :took_action).where.not(alternative_action_id: nil).first
    both&.update!(gave_in: true)

    puts "記録を作成: #{user.urges.count}件"
    puts "現在の連続日数: #{user.urges.current_streak}日"
  end
end
