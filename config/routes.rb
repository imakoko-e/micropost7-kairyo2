Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    sessions: 'users/sessions',
    unlocks: 'users/unlocks',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    # 確認待ち画面。id は URL に載せず、署名付きトークンをクエリで渡す（id を推測されてメールアドレスが見えないように）
    # URL 例: /users/confirm_wait?sig=XXXX
    get "users/confirm_wait", to: "users/registrations#confirm_wait", as: :wait_for_confirmation
    # 登録ユーザーの削除
    delete 'users/:id', to: 'users/registrations#destroy', as: :destroy_user
    # メールとパスワードの独立画面（ログイン必須）
    get   '/account/email/edit',    to: 'users/registrations#edit_email',    as: :edit_email
    patch '/account/email',         to: 'users/registrations#update_email'
    get   '/account/password/edit', to: 'users/registrations#edit_password', as: :edit_password
    patch '/account/password',      to: 'users/registrations#update_password'
  end

  # メールの確認の後、待機していたタブでログインさせる（引換券の受け取り）
  post "auth/handoff" => "auth_handoffs#create"

  mount ActionCable.server => '/cable'

  # ログインユーザー自身のプロフィール情報（個人情報）を扱う
  # URLは /profile, /profile/edit のようになる
  resource :profile, only: [:show, :edit, :update]
  # 入力確認画面（edit → confirm → update の間）
  post 'profile/confirm', to: 'profiles#confirm', as: :confirm_profile

  # 公開プロフィールなど（他人の閲覧）
  resources :users, only: [:index, :show] do
    member do
      get :following, :followers
    end
  end

  # メール確認画面
  get 'page/mail_check', to: 'pages#mail_check'

  root   "static_pages#home"                  # トップページ表示
  get    "/help",    to: "static_pages#help"
  get    "/about",   to: "static_pages#about"
  get    "/contact", to: "static_pages#contact"

  resources :microposts,          only: [:create, :destroy]
  resources :relationships,       only: [:create, :destroy]
  # 投稿に失敗した画面で再読み込みすると GET /microposts になり、ルートが無いエラーになるのを防ぐ
  get '/microposts', to: 'static_pages#home'

  if Rails.env.development?
    # 開発用のメールの受信箱（letter_opener_web）
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end


end
