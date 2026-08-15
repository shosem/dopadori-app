class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Devise の既定は root_path だが、root は authenticate_user! で保護されている。
  # そのままだとログアウト直後に保護ページを踏んで弾かれ、Devise が出した
  # 「ログアウトしました」の notice が「ログインもしくはアカウント登録してください」の
  # alert に上書きされる。自分から出ていった人に、赤い帯で入場を求める形になっていた。
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
