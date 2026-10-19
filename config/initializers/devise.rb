# frozen_string_literal: true

# Assuming you have not yet modified this file, each configuration option below
# is set to its default value. Note that some are commented out while others
# are not: uncommented lines are intended to protect your configuration from
# breaking changes in upgrades (i.e., in the event that future versions of
# Devise change the default values for those options).
# このファイルをまだ変更していないと仮定すると、以下の各構成オプションはデフォルト値に設定されます。 コメント化されていない行もあれば、コメント化されていない行もあることに注意してください。コメントされていない行は、アップグレード時の破壊的な変更から構成を保護することを目的としています (つまり、Devise の将来のバージョンでこれらのオプションのデフォルト値が変更された場合)。
#
# Use this hook to configure devise mailer, warden hooks and so forth.
# このフックを使用して、デバイスメーラー、ウォーデンフックなどを設定します。
# Many of these configuration options can be set straight in your model.
# これらの構成オプションの多くは、モデル内で直接設定できます。

Devise.setup do |config|
  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  # Devise が使用する秘密鍵。 Devise はこのキーを使用してランダムなトークンを生成します。 このキーを変更すると、データベース内の既存の確認、パスワードのリセット、およびロック解除トークンがすべて無効になります。
  # Devise will use the `secret_key_base` as its `secret_key`
  # by default. You can change it below and use your own secret key.
  # Devise はデフォルトで `secret_key_base` を `secret_key` として使用します。 以下で変更して、独自の秘密キーを使用できます。
  # config.secret_key = '<openssl rand -hex 64 で作った値>'

  # ==> Controller configuration
  # Configure the parent class to the devise controllers.
  # ==> コントローラーの設定
  # 親クラスをデバイスコントローラーに設定します。
  # config.parent_controller = 'DeviseController'

  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in Devise::Mailer,
  # note that it will be overwritten if you use your own mailer class
  # with default "from" parameter.
  # ==> メーラーの設定
  # Devise::Mailer に表示される電子メール アドレスを設定します。
  # デフォルトの "from" パラメーターを使用して独自のメーラー クラスを使用すると、上書きされることに注意してください。
  #config.mailer_sender = 'test-devise@example.com'
  config.mailer_sender = ENV.fetch("MAIL_FROM", "no-reply@example.com")

  # Configure the class responsible to send e-mails.
  # 電子メールの送信を担当するクラスを構成します。
  # config.mailer = 'Devise::Mailer'

  # Configure the parent class responsible to send e-mails.
  # 電子メールの送信を担当する親クラスを構成します。
  # config.parent_mailer = 'ActionMailer::Base'

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  # ==> ORM設定
  # ORM をロードして構成します。 デフォルトで:active_record (デフォルト) および :mongoid (bson_ext 推奨) をサポートします。 他の ORM は追加の gem として利用できる場合があります。
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  # ==> 認証メカニズムの構成
  # ユーザーの認証時にどのキーを使用するかを設定します。 デフォルトは単に :email です。 [:username, :subdomain] を使用するように設定できるため、ユーザーを認証するには両方のパラメーターが必要です。 これらのパラメータは認証時にのみ使用され、セッションからの取得時には使用されないことに注意してください。 権限が必要な場合は、それを before フィルターに実装する必要があります。 値が存在しない場合に認証を中止するかどうかを決定するブール値のハッシュを指定することもできます。
  # config.authentication_keys = [:email]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # 認証に使用されるリクエスト オブジェクトからパラメータを設定します。 指定された各エントリはリクエスト メソッドである必要があり、それは自動的に find_for_authentication メソッドに渡され、モデル検索で考慮されます。 たとえば、:request_keys を [:subdomain] に設定すると、認証に :subdomain が使用されます。 Authentication_keys について説明したのと同じ考慮事項が request_keys にも当てはまります。
  # config.request_keys = []

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  # 大文字と小文字を区別しない認証キーを構成します。 これらのキーは、ユーザーの作成または変更時、およびユーザーの認証または検索に使用されるときに小文字に変換されます。 デフォルトは:電子メールです。
  config.case_insensitive_keys = [:email]

  # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  # どの認証キーに空白を削除するかを設定します。 これらのキーは、ユーザーの作成または変更時、およびユーザーの認証または検索に使用されるときに削除される前後に空白が含まれます。 デフォルトは:電子メールです。
  config.strip_whitespace_keys = [:email]

  # Tell if authentication through request.params is enabled. True by default.
  # It can be set to an array that will enable params authentication only for the
  # given strategies, for example, `config.params_authenticatable = [:database]` will
  # enable it only for database (email + password) authentication.
  # request.params による認証が有効かどうかを通知します。 デフォルトでは true。 指定された戦略に対してのみ params 認証を有効にする配列に設定できます。たとえば、`config.params_authenticatable = [:database]` はデータベース (電子メール + パスワード) 認証に対してのみ有効になります。
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Auth is enabled. False by default.
  # It can be set to an array that will enable http authentication only for the
  # given strategies, for example, `config.http_authenticatable = [:database]` will
  # enable it only for database authentication.
  # For API-only applications to support authentication "out-of-the-box", you will likely want to
  # enable this with :database unless you are using a custom strategy.
  # HTTP Auth による認証が有効かどうかを示します。 デフォルトでは False です。 指定された戦略に対してのみ http 認証を有効にする配列に設定できます。たとえば、`config.http_authenticatable = [:database]` と指定すると、データベース認証に対してのみ有効になります。 API 専用アプリケーションが「すぐに使える」認証をサポートするには、カスタム戦略を使用していない限り、:database でこれを有効にする必要があるでしょう。
  # The supported strategies are:
  # サポートされている戦略は次のとおりです。
  # :database      = Support basic authentication with authentication key + password
  # config.http_authenticatable = false

  # If 401 status code should be returned for AJAX requests. True by default.
  # AJAX リクエストに対して 401 ステータス コードを返す必要がある場合。 デフォルトでは true。
  # config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication. 'Application' by default.
  # Http Basic 認証で使用されるレルム。 デフォルトでは「アプリケーション」。
  # config.http_authentication_realm = 'Application'

  # It will change confirmation, password recovery and other workflows
  # to behave the same regardless if the e-mail provided was right or wrong.
  # Does not affect registerable.
  # 提供された電子メールが正しいか間違っているかに関係なく、確認、パスワード回復、その他のワークフローが同じように動作するように変更されます。 登録可能には影響しません。
  # パスワード再設定などで「そのメールアドレスが登録済みかどうか」を推測されにくくなります。
  config.paranoid = true

  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  # Notice that if you are skipping storage for all authentication paths, you
  # may want to disable generating routes to Devise's sessions controller by
  # passing skip: :sessions to `devise_for` in your config/routes.rb
  # デフォルトでは、Devise はユーザーをセッションに保存します。 このオプションを設定すると、特定の戦略のストレージをスキップできます。 すべての認証パスのストレージをスキップしている場合は、config/routes.rb の `devise_for` にスキップ: :sessions を渡すことで、Devise のセッション コントローラーへのルートの生成を無効にすることができます。

  # By default, Devise cleans up the CSRF token on authentication to
  # avoid CSRF token fixation attacks. This means that, when using AJAX
  # requests for sign in and sign up, you need to get a new CSRF token
  # from the server. You can disable this option at your own risk.
  # デフォルトでは、Devise は認証時に CSRF トークンをクリーンアップして、CSRF トークン固定化攻撃を回避します。 つまり、サインインとサインアップに AJAX リクエストを使用する場合は、サーバーから新しい CSRF トークンを取得する必要があります。 このオプションは自己責任で無効にすることができます。
  # config.clean_up_csrf_token_on_authentication = true

  # When false, Devise will not attempt to reload routes on eager load.
  # This can reduce the time taken to boot the app but if your application
  # requires the Devise mappings to be loaded during boot time the application
  # won't boot properly.
  # false の場合、Devise は積極的なロードでルートをリロードしようとしません。
  # これにより、アプリの起動にかかる時間を短縮できますが、アプリケーションが起動時に Devise マッピングをロードする必要がある場合、アプリケーションは適切に起動しません。
  config.reload_routes = true

  # ==> Configuration for :database_authenticatable
  # ==> :database_authenticatable の設定
  # For bcrypt, this is the cost for hashing the password and defaults to 12. If
  # using other algorithms, it sets how many times you want the password to be hashed.
  # The number of stretches used for generating the hashed password are stored
  # with the hashed password. This allows you to change the stretches without
  # invalidating existing passwords.
  # bcrypt の場合、これはパスワードをハッシュするためのコストであり、デフォルトは 12 です。他のアルゴリズムを使用する場合は、パスワードをハッシュする回数を設定します。 ハッシュ化されたパスワードの生成に使用されたストレッチの数は、ハッシュ化されたパスワードとともに保存されます。 これにより、既存のパスワードを無効にすることなくストレッチを変更できます。
  #
  # Limiting the stretches to just one in testing will increase the performance of
  # your test suite dramatically. However, it is STRONGLY RECOMMENDED to not use
  # a value less than 10 in other environments. Note that, for bcrypt (the default
  # algorithm), the cost increases exponentially with the number of stretches (e.g.
  # a value of 20 is already extremely slow: approx. 60 seconds for 1 calculation).
  # テスト中のストレッチを 1 つに限定すると、テスト スイートのパフォーマンスが大幅に向上します。 ただし、他の環境では 10 未満の値を使用しないことが強く推奨されます。 bcrypt (デフォルトのアルゴリズム) の場合、コストはストレッチの数に応じて指数関数的に増加することに注意してください (たとえば、値 20 はすでに非常に遅いです: 1 回の計算で約 60 秒)。
  config.stretches = Rails.env.test? ? 1 : 12

  # Set up a pepper to generate the hashed password.
  # ハッシュ化されたパスワードを生成するために Pepper を設定します。
  # config.pepper = '<openssl rand -hex 64 で作った値>'

  # Send a notification to the original email when the user's email is changed.
  # ユーザーの電子メールが変更されたときに、元の電子メールに通知を送信します。
  # config.send_email_changed_notification = false

  # Send a notification email when the user's password is changed.
  # ユーザーのパスワードが変更されたときに通知メールを送信します。
  # config.send_password_change_notification = false

  # ========================
  # Confirmable（メール認証）
  # ========================
  # ==> Configuration for :confirmable
  # A period that the user is allowed to access the website even without
  # confirming their account. For instance, if set to 2.days, the user will be
  # able to access the website for two days without confirming their account,
  # access will be blocked just in the third day.
  # You can also set it to nil, which will allow the user to access the website
  # without confirming their account.
  # Default is 0.days, meaning the user cannot access the website without
  # confirming their account.
  # ==> :confirmable の設定
  # ユーザーがアカウントを認証しなくてもウェブサイトにアクセスできる期間。
  # たとえば、2.days に設定すると、ユーザーはアカウントを確認せずに 2 日間 Web サイトにアクセスできますが、3 日目にアクセスがブロックされます。
  # nil に設定することもできます。これにより、ユーザーはアカウントを確認せずに Web サイトにアクセスできるようになります。
  # デフォルトは 0.days で、ユーザーはアカウントを確認せずに Web サイトにアクセスできないことを意味します。
  # config.allow_unconfirmed_access_for = 2.days
  # メール認証待ちの間にログインを許可する時間
  # 0の場合は「確認完了までログイン不可」。短期の許可を出す場合は、例: 2.days など。
  config.allow_unconfirmed_access_for = 0.days        # メール確認が終わるまでログイン不可（いちばん挙動が安定します）

  # A period that the user is allowed to confirm their account before their
  # token becomes invalid. For example, if set to 3.days, the user can confirm
  # their account within 3 days after the mail was sent, but on the fourth day
  # their account can't be confirmed with the token any more.
  # Default is nil, meaning there is no restriction on how long a user can take
  # before confirming their account.
  # トークンが無効になる前にユーザーがアカウントを確認できる期間。
  # たとえば、3.days に設定すると、ユーザーはメールの送信後 3 日以内にアカウントを確認できますが、4 日目にはトークンを使用してアカウントを確認できなくなります。
  # デフォルトは nil で、ユーザーがアカウントを確認するまでの時間に制限がないことを意味します。
  # config.confirm_within = 3.days

  # If true, requires any email changes to be confirmed (exactly the same way as
  # initial account confirmation) to be applied. Requires additional unconfirmed_email
  # db field (see migrations). Until confirmed, new email is stored in
  # unconfirmed_email column, and copied to email column on successful confirmation.
  # true の場合、電子メールの変更を適用するために確認する必要があります (最初のアカウント確認とまったく同じ方法)。
  # 追加の unconfirmed_email データベース フィールドが必要です (移行を参照)。
  # 確認されるまで、新しい電子メールは unconfirmed_email 列に保存され、確認が成功すると email 列にコピーされます。
  # すでに確認済みのユーザがメールアドレス変更を行った場合、
  # 新しいアドレスに確認メールを送り、確認完了まで旧アドレスでログインさせる動作を有効化
  # ほぼ常に true 推奨（なりすまし/誤登録対策）
  config.reconfirmable = true         # メール変更時は再確認が必要（基本true推奨）

  # Defines which key will be used when confirming an account
  # アカウントを確認するときに使用するキーを定義します
  # 確認リンクを受け取るキー（通常は :email のみ）
  # 複数キーを使う場合は [:email, :username] のように配列で指定
  config.confirmation_keys = [:email]

  # ========================
  # Rememberable（任意）
  # ========================
  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  # ==> :rememberable の設定
   # 資格情報を再度要求せずにユーザーが記憶される時間。
  # 「ログイン状態を保持する（remember me）」の有効期限
  # 機密度が高いサービスは短め、BtoCは数週間〜数ヶ月もあり得る
  # config.remember_for = 2.weeks

  # Invalidates all the remember me tokens when the user signs out.
  # ユーザーがサインアウトすると、すべての Remember me トークンが無効になります。
  config.expire_all_remember_me_on_sign_out = true

  # If true, extends the user's remember period when remembered via cookie.
  # true の場合、Cookie 経由で記憶される場合、ユーザーの記憶期間が延長されます。
  # config.extend_remember_period = false

  # Options to be passed to the created cookie. For instance, you can set
  # secure: true in order to force SSL only cookies.
  # 作成された Cookie に渡されるオプション。 たとえば、SSL のみの Cookie を強制するために secure: true を設定できます。
  # config.rememberable_options = {}

  # ==> Configuration for :validatable
  # Range for password length.
  # ==> :validable の設定
  # パスワードの長さの範囲。
  config.password_length = 6..128

  # Email regex used to validate email formats. It simply asserts that
  # one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  # 電子メール形式を検証するために使用される電子メール正規表現。 これは、指定された文字列に @ が 1 つ (そして 1 つだけ) 存在することを主張するだけです。 これは主にユーザーにフィードバックを提供することが目的であり、電子メールの正当性を主張するものではありません。
  config.email_regexp = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  # ========================
  # Timeoutable（セッション有効期限）
  # ========================
  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again. Default is 30 minutes.
  # ==> :timeoutable の設定
  # アクティビティのないユーザーセッションをタイムアウトする時間。 この時間が経過すると、ユーザーは再度資格情報の入力を求められます。 デフォルトは 30 分です。
  # 一定時間操作がなければ自動ログアウト（セキュリティ強化）
  # BtoCなら 30〜60分、BtoB管理画面なら 15〜30分など
  config.timeout_in = 60.minutes          # 30〜60分が目安（B2Bは短め、B2Cは長めも可）

  # ========================
  # Lockable（アカウントロック）
  # ========================
  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  # ==> :lockable の設定
  # アカウントをロックするために使用される戦略を定義します。 :failed_attempts = サインイン試行が何度も失敗した後、アカウントをロックします。 :none = ロック戦略なし。 ロックは自分で処理する必要があります。
  # ロック戦略: :failed_attempts（失敗回数でロック）が一般的
  config.lock_strategy = :failed_attempts

  # Defines which key will be used when locking and unlocking an account
  # アカウントをロックおよびロック解除するときに使用するキーを定義します
  # config.unlock_keys = [:email]

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  # アカウントのロックを解除するために使用される戦略を定義します。
  # :email = ロック解除リンクをユーザーの電子メールに送信します
  # :time = 一定時間が経過した後にログインを再度有効にします (下記の :unlock_in を参照)
  # :both = 両方の戦略を有効にします
  # :none = ロック解除戦略はありません。 ロック解除はご自身で行ってください。
  # アンロック方法: :email（解除メール）/ :time（時間経過）/ :both（両方）
  # 一般的には :both がバランス良い
  config.unlock_strategy = :both      # メール解除 + 自動解除の両方

  # Number of authentication tries before locking an account if lock_strategy
  # is failed attempts.
  # lock_strategy が試行に失敗した場合に、アカウントをロックするまでの認証試行の回数。
  # ログイン失敗何回でロックするか（5〜10程度が目安）
  config.maximum_attempts = 10          # 失敗10回でロック（5〜10が目安）

  # Time interval to unlock the account if :time is enabled as unlock_strategy.
  # :time がunlock_strategyとして有効になっている場合、アカウントのロックを解除する時間間隔。
  # 自動解除までの時間（解除メールを見逃しても復帰できるように）
  config.unlock_in = 1.hour           # 1時間で自動解除

  # Warn on the last attempt before the account is locked.
  # アカウントがロックされる前の最後の試行時に警告します。
  # 最後の試行（ロック直前）で警告メールを送る
  config.last_attempt_warning = true          # ロック直前に警告メール

  # ==> Configuration for :recoverable
  # Defines which key will be used when recovering the password for an account
  # ==> :recoverable の設定
  # アカウントのパスワードを回復するときに使用するキーを定義します
  # config.reset_password_keys = [:email]

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  # パスワードリセットキーを使用してパスワードをリセットできる時間間隔。 間隔が小さすぎると、ユーザーがパスワードを変更する時間がなくなります。
  config.reset_password_within = 6.hours

  # When set to false, does not sign a user in automatically after their password is
  # reset. Defaults to true, so a user is signed in automatically after a reset.
  # false に設定すると、パスワードがリセットされた後にユーザーは自動的にサインインしません。 デフォルトは true なので、ユーザーはリセット後に自動的にサインインします。
  # config.sign_in_after_reset_password = true

  # ==> Configuration for :encryptable
  # Allow you to use another hashing or encryption algorithm besides bcrypt (default).
  # You can use :sha1, :sha512 or algorithms from others authentication tools as
  # :clearance_sha1, :authlogic_sha512 (then you should set stretches above to 20
  # for default behavior) and :restful_authentication_sha1 (then you should set
  # stretches to 10, and copy REST_AUTH_SITE_KEY to pepper).
  # Require the `devise-encryptable` gem when using anything other than bcrypt
  # ==> :encryptable の設定
  # bcrypt (デフォルト) 以外の別のハッシュまたは暗号化アルゴリズムを使用できるようにします。 :sha1、:sha512、または他の認証ツールのアルゴリズムを :clearance_sha1、:authlogic_sha512 (デフォルトの動作では上記のストレッチを 20 に設定する必要があります) および :restful_authentication_sha1 (その後、ストレッチを 10 に設定し、REST_AUTH_SITE_KEY を Pepper にコピーする必要があります) として使用できます。 ）。
  # bcrypt 以外を使用する場合は `devise-encryptable` gem が必要です
  # config.encryptor = :sha512

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # ==> スコープの設定
  # スコープ付きビューをオンにします。 「sessions/new」をレンダリングする前に、まず「users/sessions/new」をチェックします。 デフォルトのビューのみを使用している場合は速度が低下するため、デフォルトではオフになっています。
  # config.scoped_views = false

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes (usually :user).
  # Warden に与えられるデフォルトのスコープを設定します。 デフォルトでは、これはルートで宣言された最初のデバイスロール (通常は:user) です。
  # config.default_scope = :user

  # Set this configuration to false if you want /users/sign_out to sign out
  # only the current scope. By default, Devise signs out all scopes.
  # /users/sign_out が現在のスコープのみをサインアウトするようにする場合は、この構成を false に設定します。 デフォルトでは、Devise はすべてのスコープをサインアウトします。
  # config.sign_out_all_scopes = true

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  #
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists.
  #
  # The "*/*" below is required to match Internet Explorer requests.
  # ==> ナビゲーション設定
  # ナビゲーションとして扱う必要がある形式をリストします。 ユーザーがアクセス権を持っていない場合、
  # :html などの形式はサインイン ページにリダイレクトする必要がありますが、:xml や :json などの形式は 401 を返す必要があります。
  # :iphone や :mobile などの追加のナビゲーション形式がある場合は、それらをナビゲーション形式リストに追加する必要があります。
  # 以下の「*/*」は、Internet Explorer の要求と一致するために必要です。
  config.navigational_formats = ['*/*', :html, :turbo_stream]
  # :turbo_stream を追加することで、Devise は Turbo Stream のリクエストを HTML のリクエストと同様に扱うようになります

  # The default HTTP method used to sign out a resource. Default is :delete.
  # リソースをサインアウトするために使用されるデフォルトの HTTP メソッド。 デフォルトは:削除です。
  config.sign_out_via = :delete

  # ==> OmniAuth
  # Add a new OmniAuth provider. Check the wiki for more information on setting up on your models and hooks.
  # ==> オムニ認証
  # 新しい OmniAuth プロバイダーを追加します。 モデルとフックのセットアップの詳細については、Wiki を確認してください。
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'
  config.omniauth :google_oauth2, ENV['GOOGLE_OAUTH_CLIENT_ID'], ENV['GOOGLE_OAUTH_CLIENT_SECRET']


  # ==> Warden configuration
  # If you want to use other strategies, that are not supported by Devise, or
  # change the failure app, you can configure them inside the config.warden block.
  #
  # ==> 監視員の設定
  # Devise でサポートされていない他の戦略を使用する場合、または失敗したアプリを変更する場合は、config.warden ブロック内でそれらを構成できます。
  # config.warden do |manager|
  #   manager.intercept_401 = false
  #   manager.default_strategies(scope: :user).unshift :some_external_strategy
  # end

  # ==> Mountable engine configurations
  # ==> 搭載可能なエンジン構成
  # When using Devise inside an engine, let's call it `MyEngine`, and this engine
  # is mountable, there are some extra configurations to be taken into account.
  # The following options are available, assuming the engine is mounted as:
  # エンジン内で Devise を使用する場合、これを「MyEngine」と呼びます。このエンジンはマウント可能ですが、考慮すべき追加の構成がいくつかあります。
  # エンジンが次のようにマウントされていると仮定すると、次のオプションが利用可能です。
  #     mount MyEngine, at: '/my_engine'
  # The router that invoked `devise_for`, in the example above, would be:
  # 上記の例で `devise_for` を呼び出したルーターは次のようになります。
  # config.router_name = :my_engine
  # When using OmniAuth, Devise cannot automatically set OmniAuth path,
  # so you need to do it manually. For the users scope, it would be:
  # OmniAuth を使用する場合、Devise は OmniAuth パスを自動的に設定できないため、手動で行う必要があります。 ユーザーのスコープの場合は次のようになります。
  # config.omniauth_path_prefix = '/my_engine/users/auth'

  # ==> Hotwire/Turbo configuration
  # When using Devise with Hotwire/Turbo, the http status for error responses
  # and some redirects must match the following. The default in Devise for existing
  # apps is `200 OK` and `302 Found respectively`, but new apps are generated with
  # these new defaults that match Hotwire/Turbo behavior.
  # Note: These might become the new default in future versions of Devise.
  # ==> ホットワイヤー/ターボ構成
  # Hotwire/Turbo で Devise を使用する場合、エラー応答と一部のリダイレクトの http ステータスは次と一致する必要があります。
  # Devise の既存アプリのデフォルトはそれぞれ「200 OK」と「302 Found」ですが、新しいアプリは Hotwire/Turbo の動作に一致するこれらの新しいデフォルトで生成されます。
  # 注: これらは、Devise の将来のバージョンで新しいデフォルトになる可能性があります。
  config.responder.error_status = :unprocessable_entity       # エラー時に422返却
  config.responder.redirect_status = :see_other               # リダイレクトに303返却

  # ==> Configuration for :registerable
  # ==> :registerable の設定
  # When set to false, does not sign a user in automatically after their password is
  # changed. Defaults to true, so a user is signed in automatically after changing a password.
  # false に設定すると、パスワードの変更後にユーザーは自動的にサインインしません。 デフォルトは true なので、ユーザーはパスワードの変更後に自動的にサインインします。
  # config.sign_in_after_change_password = true
  # Deviseの秘密鍵を明示して固定する
  # 優先順: 環境変数 > credentials.devise_secret_key > credentials.secret_key_base > ENV["SECRET_KEY_BASE"]
  config.secret_key = ENV["DEVISE_SECRET_KEY"] ||
                      Rails.application.credentials.dig(:devise_secret_key) ||
                      Rails.application.credentials.secret_key_base ||
                      ENV["SECRET_KEY_BASE"]


end
