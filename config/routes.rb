Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "tops#top"

  # ログイン不要のお試し。円を押して 3-3-6 呼吸だけ体験する(記録は作らない)。
  # 何も保存しないので GET にしてある。POST にするとリロードで再送信の確認が出る。
  get "try" => "trials#new", as: :try
  get "try/result" => "trials#result", as: :try_result
  resources :alternative_actions, except: [ :show ]
  resources :urges, only: %i[ new create edit update index show ] do
    member do
      get :suggestions
      # 状態はコントローラが決める、を守るため update に相乗りさせない。
      # update は既に3つの分岐(took_action / 提案へ / calmed)を持っている。
      patch :gave_in
    end

    collection do
      # 衝動ボタンを押す間もなく直行した分を、あとから1件作る(requirements.md 5章 B)。
      # create(連打完了で作る)と混ぜない。混ぜると、あの create! が
      # 「何が起きて作られた記録か」を表さなくなる。
      get :gave_in, action: :new_gave_in
      post :gave_in, action: :create_gave_in
    end
  end
end
