class TopsController < ApplicationController
  before_action :authenticate_user!

  def top
    @streak = current_user.urges.current_streak
  end
end
