class AlternativeActionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_alternative_action, only: %i[ edit update destroy ]

  def index
    @alternative_actions = current_user.all.order(:time_span, :created_at)
  end

  def new
    @alternative_action = current_user.alternative_actions.build
  end

  def create
    @alternative_action = current_user.alternative_actions.build(alternative_action_params)
    if @alternative_action.save
      redirect_to alternative_actions_path, notice: "代替行動を登録しました"
    else
      flash.now[:alert] = "登録できませんでした"
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @alternative_action.update(alternative_action_params)
      redirect_to alternative_actions_path, notice: "代替行動を更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @alternative_action.destroy!
    redirect_to alternative_actions_path, notice: "代替行動を削除しました", status: :see_other
  end

  private

  def set_alternative_action
    @alternative_action = current_user.alternative_actions.find(params[:id])
  end

  def alternative_action_params
    params.expect(alternative_action: [ :title, :time_span ])
  end
end
