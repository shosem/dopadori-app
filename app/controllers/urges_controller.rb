class UrgesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_urge, only: %i[show edit update suggestions gave_in]

  def index
    @daily_counts = current_user.urges.daily_counts
    @urges_by_date = current_user.urges.recent.includes(:alternative_action).group_by { |urge| urge.created_at.in_time_zone.to_date }
  end

  def new
    @urge = current_user.urges.build
  end

  def create
    @urge = current_user.urges.create!
    redirect_to edit_urge_path(@urge)
  end

  def show; end

  # 衝動ボタンを押す間もなく直行した分を、あとから記録する(requirements.md 5章 B)。
  # resolved は pending のまま。3-3-6 を通っていないので、記録すべき結果が存在しない。
  def new_gave_in
    @urge = current_user.urges.build(gave_in: true, occurred_on: Time.zone.today)
  end

  def create_gave_in
    @urge = current_user.urges.build(gave_in: true, **gave_in_new_params)
    @urge.created_at = Urge.occurred_at(@urge.occurred_on)

    # 未来の記録は棒グラフの窓にもストリークにも入らないので、作れてしまうと
    # 「どこからも見えない記録」になる。form の max だけに頼らず、ここで弾く。
    if @urge.created_at > Time.zone.now
      flash.now[:alert] = "これから先の日付は選べません"
      return render :new_gave_in, status: :unprocessable_content
    end

    @urge.save!
    redirect_to urge_path(@urge), notice: "記録しました"
  end

  def edit; end

  # 「我慢できなかった」の付け外し。トグルなので確認ダイアログは挟まず、
  # 代わりに flash で向きを伝える(押し間違えても何が起きたか分かるようにする)。
  def gave_in
    @urge.update!(gave_in_params)

    notice = @urge.gave_in? ? "我慢できなかった記録をつけました" : "取り消しました"
    redirect_to urge_path(@urge), notice: notice
  end

  def update
    if params[:alternative_action_id]
      action = current_user.alternative_actions.find(params[:alternative_action_id])
      @urge.update!(alternative_action: action, resolved: :took_action)
      redirect_to root_path, notice: "記録しました"
    elsif @urge.update(urge_params)
      if params[:next] == "suggestions"
        redirect_to suggestions_urge_path(@urge)
      else
        @urge.calmed!
        redirect_to root_path, notice: "記録しました"
      end
    else
      flash.now[:alert] = "記録できませんでした"
      render :edit, status: :unprocessable_content
    end
  end


  def suggestions
    grouped = current_user.alternative_actions.group_by(&:time_span)
    grouped = grouped.transform_values { |actions| [ actions.sample ] } unless params[:all]
    @suggestions = AlternativeAction.time_spans.keys.filter_map { |span| [ span, grouped[span] ] if grouped[span] }
  end

  private

  def set_urge
    @urge = current_user.urges.find(params[:id])
  end

  def urge_params
    params.expect(urge: [ :trigger, :memo ])
  end

  # 連打フローの urge_params とは分ける。あちらに :gave_in を足すと、
  # 入力画面から状態を送り込めるようになってしまう。
  def gave_in_params
    params.expect(urge: [ :gave_in ])
  end

  # occurred_on は列ではなく、created_at をどの日に置くかの入力。
  # created_at を直接受け取らないのは、時刻まで送り込めるようにしないため。
  def gave_in_new_params
    params.expect(urge: [ :occurred_on, :memo ])
  end
end
