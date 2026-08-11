class UrgesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_urge, only: %i[edit update suggestions]

  def new
    @urge = current_user.urges.build
  end

  def create
    @urge = current_user.urges.create!
    redirect_to edit_urge_path(@urge)
  end

  def edit; end

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
    grouped = grouped.transform_values { |actions| [actions.sample] } unless params[:all]
    @suggestions = AlternativeAction.time_spans.keys.filter_map { |span| [span, grouped[span]] if grouped[span] }
  end

  private

  def set_urge
    @urge = current_user.urges.find(params[:id])
  end

  def urge_params
    params.expect(urge: [ :trigger, :memo ])
  end
end
