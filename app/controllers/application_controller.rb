class ApplicationController < ActionController::Base
  # Devise の forget_me（remember_me のクッキーを消す）を使う
  include Devise::Controllers::Rememberable
  # メール確認のリンクから来たときは、前の remember_me のクッキーを先に消す
  before_action :clean_up_session_for_confirmation, if: -> { controller_name == 'confirmations' && action_name == 'show' }

  private def clean_up_session_for_confirmation
    # Devise の :user スコープの remember_me のクッキー
    key = :remember_user_token
    data = cookies.signed[key]
    user_id = data.is_a?(Array) ? data.first : nil
    if user_id.present?
      user = User.find_by(id: user_id)
      forget_me(user) if user
    end
    # reset_session はしない。別のタブの待機画面の WebSocket が切れ、Cookie の配り直しとぶつかるため
  end

  # Devise の画面で、name も受け取れるようにする（ストロングパラメータ）
  before_action :configure_permitted_parameters, if: :devise_controller?

  # ログインの後に戻る先として、いま開いた画面の URL を覚えておく
  # （Devise の after_sign_in_path_for が stored_location_for で読む）
  after_action :store_action
  def store_action
    return unless request.get?

    # ログインしているときだけ覚える（ログインの前後の画面は覚えない）
    return unless user_signed_in? rescue false

    path = request.path
    return if [
      "/users/sign_in", "/login",
      "/users/sign_up",
      "/users/password/new", "/users/password/edit",
      "/users/confirmation",  # 確認フロー
      "/users/sign_out",
      "/logout"
    ].include?(path)

    return if request.xhr?

    store_location_for(:user, request.fullpath)
  end

  # ログアウトの後はトップへ
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # 本番では、ホストとスキームを CANONICAL_HOST・https にそろえる（同じオリジンにする）
  before_action :enforce_canonical_host, if: -> { Rails.env.production? && ENV["CANONICAL_HOST"].present? }

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  private

  def enforce_canonical_host
    expected_host = ENV["CANONICAL_HOST"]  # 正規ホスト（.env で指定）
    expected_scheme = "https"
    if request.host != expected_host || request.scheme != expected_scheme
      redirect_to "#{expected_scheme}://#{expected_host}#{request.fullpath}", allow_other_host: true, status: :moved_permanently
    end
  end

end
