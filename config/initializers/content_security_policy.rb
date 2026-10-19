# アプリケーション全体のコンテンツ セキュリティ ポリシーを定義します。
# 詳細については、「Rails アプリケーションの保護ガイド」を参照してください。
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # 基本ルール：自分のサイトから来たものだけ許可。他はデフォルト禁止
    policy.default_src :self
    policy.font_src    :self, :https, :data
    # 画像は自サイト・https・data URL・blob を許可（ActiveStorage のプレビュー等のため）
    policy.img_src     :self, :https, :data, :blob
    # <object>（Flash等の旧プラグイン）は全面禁止（安全側）
    policy.object_src  :none
    # JavaScript は「自サイト」か「https の外部」のみ。インラインの <script>…</script> は原則禁止
    policy.script_src  :self, :https
    # CSS は自サイト・https に加え、インラインstyleも許可（unsafe_inline）
    policy.style_src   :self, :https, :unsafe_inline
    # ActionCable は同一オリジン（nginx 経由の /cable）へ wss で接続する。
    # :self でも同一オリジンの WebSocket は概ね許可されるが、ブラウザ差異を避けるため本番ホストの wss を明示する
    # 通信（fetch/WebSocket）の接続先。ActionCable の wss を明示的に許可
    policy.connect_src :self, :https,
                       "wss://#{ENV.fetch('CANONICAL_HOST', 'example.com')}",
                       "wss://www.#{ENV.fetch('CANONICAL_HOST', 'example.com')}"
    # <base> タグの乗っ取りを防ぐ
    policy.base_uri    :self
    # あなたのページを他サイトの iframe に埋め込ませない（クリックジャッキング対策）
    policy.frame_ancestors :self
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # importmap-rails が出力するインラインスクリプト（importmap JSON とエントリポイントの<script type="module">）に nonce を付与するための設定。
  # これを有効にしないと script_src がインラインスクリプトをブロックし、JS（Stimulus 含む）が一切起動しない。
  # nonce は Turbo のキャッシュと整合させるためセッション単位で安定させる
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)

  # ポリシーを強制することなく違反を報告する。
  # config.content_security_policy_report_only = true
  config.content_security_policy_report_only = false
end