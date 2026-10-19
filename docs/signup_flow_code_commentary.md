# サインアップ処理フロー コード解説資料

作成 — 2026年4月22日
対象 — サインアップ（新規登録 → メール確認 → 自動ログイン）に関わる12ファイルを、Rails 初心者向けに詳細解説した資料。
補足 — 解説は、2026年4月21日のリファクタリング（Claude Code による）の後のコードを元にしている。各節の「2026年4月16日 → 4月21日 の変更点」は、そのリファクタリングの記録。
更新 — 2026年10月。公開版のコードに合わせ、④⑨⑩の解説を直した（各節の「その後の変更」）。

---

## 0. 全体像（先に読むと理解が早い）

本アプリのサインアップは「**2つのタブをまたぐ自動ログイン**」を実現している。

- **タブA（待機タブ）** — サインアップフォームを送ったタブ。送信後に `/users/confirm_wait?sig=...` を開き、WebSocket でサーバからの通知を待つ。
- **タブB（確認タブ）** — メール内リンクから新規に開かれるタブ。Devise が `confirm_by_token` でメール確認を完了させ、そのタブ自身もログインする。
- タブA と タブB は別々のブラウザリクエストなので、セッション Cookie は共有されない。そこで、タブBが「引換券（handoff_token）」を WebSocket 経由でタブAに送り、タブAは `POST /auth/handoff` で引換券をセッションログインに変える。

この流れを実現するため、**署名付きトークン（`message_verifier`）**、**Redis/キャッシュの一時ストア（`WaiterRegistry` / `UsedJtiStore`）**、**ActionCable（WebSocket）** が組み合わさっている。

---

## ① `config/routes.rb`

### 目的と処理内容
URL ↔ コントローラー・アクションの対応表。サインアップ関連のルートを Devise 標準 + カスタムで定義する。

### サインアップに関わる該当箇所
```ruby
devise_for :users, controllers: {
  registrations: 'users/registrations',
  confirmations: 'users/confirmations',
  ...
}

devise_scope :user do
  # 確認待ち画面。id は URL に載せず、署名付きトークンをクエリで渡す（id を推測されてメールアドレスが見えないように）
  get "users/confirm_wait", to: "users/registrations#confirm_wait", as: :wait_for_confirmation
  ...
end

post "auth/handoff" => "auth_handoffs#create"
mount ActionCable.server => '/cable'
get 'page/mail_check', to: 'pages#mail_check'
```

### 文法レベルの解説
- `devise_for :users` は Devise gem が提供するヘルパー。`/users/sign_in` `/users/sign_up` など認証系ルートを一括生成する。`controllers:` に独自コントローラーを指定することで、Devise 標準を上書きできる。
- `devise_scope :user do ... end` は「Devise の :user スコープ配下にカスタムルートを追加する」ブロック。`devise_scope` を外で使うと Devise が正しいリソースを認識できず 404 になる。
- `get "users/confirm_wait", to: "users/registrations#confirm_wait", as: :wait_for_confirmation`
  - `to:` は「どのコントローラー#アクションに飛ばすか」。
  - `as:` は「このルートの名前（`wait_for_confirmation_path` というヘルパーが自動生成される）」。`as:` を書くことで `wait_for_confirmation_path(sig: "xxx")` のように Ruby コード内でURL組み立てができる。
- `mount ActionCable.server => '/cable'` — WebSocket のエンドポイントを `/cable` としてマウントする。これで ActionCable が動く土台ができる。

### 初心者向け補足（用語）
- **ルーティング** — 「URL を見て、どのコントローラーのどのメソッドに処理を渡すか」を決める仕組み。
- **`as:`** — 名前付きルート（`_path` / `_url` ヘルパー）を生成するための命名。
- **mount** — Rack アプリケーション（ActionCable など）を特定のパスに組み込む。ActionCable は独立した Rack アプリなので mount が必要。

### 2026年4月16日 → 4月21日 の変更点
- 以前：`get "users/confirm_wait/:id", to: "users/registrations#confirm_wait"` のように **URL に user id を直接載せていた**。
- 現在：`get "users/confirm_wait", ...`（`:id` を廃止）。代わりにクエリパラメータ `?sig=XXXX` で署名付きトークンを受け取る。
- **変更理由**：`:id` を URL に露出すると、第三者が適当な数値を差し替えるだけで他人の「確認待ち画面」にアクセスでき、**メールアドレスの漏えい**につながっていた。署名付きトークンにすることで、正規の発行元からのアクセスだけが通るようになった。

---

## ② `app/controllers/users/registrations_controller.rb`

### 目的と処理内容
Devise の `Users::RegistrationsController` を継承したユーザー登録周りの処理。特に重要なのは「確認待ち画面」を用意する `confirm_wait` と、サインアップ直後の遷移先を決める `after_inactive_sign_up_path_for`。

### サインアップに関わる該当箇所（抜粋）
```ruby
before_action :authenticate_user!, except: [:new, :create, :confirm_wait]
before_action :correct_user,   only: [:edit, :update, :destroy]
before_action :configure_sign_up_params, only: [:create]

# 「確認待ち画面」を表示するためのアクション
def confirm_wait
  uid = verify_confirm_wait_sig(params[:sig])
  unless uid
    redirect_to root_path, alert: "リンクが無効または期限切れです。"
    return
  end

  @user = User.find_by(id: uid)
  if @user.nil? || @user.confirmed?
    redirect_to root_path, alert: "無効なアクセスです。"
    return
  end

  jti = SecureRandom.hex(16)
  WaiterRegistry.set_latest_jti_for(@user.id, jti, ttl: 30.minutes)

  @waiter_sig = Rails.application.message_verifier(:waiter)
                     .generate({ uid: @user.id, jti: jti, exp: 30.minutes.from_now.to_i },
                               purpose: :waiter)
end

def after_inactive_sign_up_path_for(resource)
  sig = Rails.application.message_verifier(:confirm_wait_access)
                         .generate({ uid: resource.id, exp: 30.minutes.from_now.to_i },
                                   purpose: :confirm_wait_access)
  wait_for_confirmation_path(sig: sig)
end

def verify_confirm_wait_sig(sig)
  return nil if sig.blank?
  data = Rails.application.message_verifier(:confirm_wait_access)
                          .verify(sig, purpose: :confirm_wait_access)
  uid = data["uid"] || data[:uid]
  exp = (data["exp"] || data[:exp]).to_i
  return nil if uid.blank? || exp <= 0 || Time.at(exp) <= Time.current
  uid
rescue ActiveSupport::MessageVerifier::InvalidSignature
  nil
end
```

### 文法レベルの解説
- `class Users::RegistrationsController < Devise::RegistrationsController` — Devise 標準コントローラーを継承。`super` で親クラスの処理を呼び出せる。
- `before_action :authenticate_user!, except: [:new, :create, :confirm_wait]` — アクション実行前に認証を強制するが、サインアップ系の3つだけ除外する。未ログインでも見られる必要があるため。
- `SecureRandom.hex(16)` — 16バイト（128ビット）のランダム値を16進文字列（32文字）で返す。推測困難な ID を作るときの常套句。
- `Rails.application.message_verifier(:waiter).generate({...}, purpose: :waiter)` — Rails 標準の **メッセージ署名器**。ハッシュを文字列化し、サーバの秘密鍵で署名する。受け取り側は `verify` で検証。
  - `purpose:` は「この署名はこの用途専用」というタグ。別用途のトークンを流用される攻撃を防ぐ。
- `30.minutes.from_now.to_i` — Active Support が提供する時刻計算。整数（UNIXタイムスタンプ）に変換して保存。
- `data["uid"] || data[:uid]` — 署名データの復元時、シリアライザによってキーが文字列かシンボルかが変わるため両対応。
- `rescue ActiveSupport::MessageVerifier::InvalidSignature` — 改ざん・期限切れ時に出る例外をキャッチし、`nil` を返して「無効」として扱う。メソッド末尾の `rescue` はメソッド全体が対象。

### 初心者向け補足（用語）
- **`before_action`** — アクションの実行前に呼ばれるフィルタ。認証チェック・パラメータサニタイズなどに使う。
- **ストロングパラメータ** — `params.require(...).permit(...)` の形で「許可する属性」を明示する仕組み。Mass Assignment 脆弱性を防ぐ。
- **`devise_parameter_sanitizer`** — Devise が管理するパラメータ許可リスト。サインアップで追加属性を受け付けるのに使う。
- **`message_verifier`** — 「サーバが署名した任意のデータ」をクライアントに渡すための仕組み。JWT の Rails 版と考えてよい。

### 2026年4月16日 → 4月21日 の変更点
1. **`confirm_wait` アクションの入口を変更**
   - 以前：`User.find(params[:id])` と URL の `:id` を直接使用。未検証でユーザーを引き当てていた。
   - 現在：`verify_confirm_wait_sig(params[:sig])` で署名検証 → 成功した uid のみ使用。さらに「既に確認済みなら拒否」のチェックも早期に行う。
   - **考え方**：*信頼できる入力と信頼できない入力を分ける*。URL パラメータは必ず「検証してから使う」という形に統一した。
2. **`after_inactive_sign_up_path_for` が署名付きトークンを生成**
   - 以前：`wait_for_confirmation_path(resource.id)` で id をそのまま渡すだけ。
   - 現在：`message_verifier(:confirm_wait_access).generate({uid:, exp:})` で署名し、`wait_for_confirmation_path(sig: sig)` に。
3. **`correct_user` の脆弱性修正**
   - 以前：`redirect_to(root_url) unless @user == current_user`。Devise の `authenticate_scope!` が `@user = current_user` を先に入れてしまうので **常に真**になり、他人のIDで `destroy` が通ってしまっていた。
   - 現在：`current_user.id.to_s == params[:id].to_s` で直接比較。**実在したセキュリティバグの修正**。
4. **`verify_confirm_wait_sig` を新設**（責務を分離して可読性アップ）
5. **冗長なログや古いコメントの整理**

---

## ③ `app/views/devise/registrations/confirm_wait.html.erb`

### 目的と処理内容
「メール確認待機中」画面の HTML。Stimulus コントローラーを起動するためのデータ属性（`data-controller`, `data-*-value`）をつけるのが本質。

### 該当コード
```erb
<div class="container mt-6 pb-10"
     data-controller="confirmation"
     data-confirmation-waiter-sig-value="<%= @waiter_sig %>"
     data-turbo-permanent>

  <h2 class="mb-6 text-center">メール確認待機中</h2>

  <div class="flex justify-center">
    <div class="w-full md:w-2/3">
      <p>ご登録ありがとうございます。確認用のメールを <strong><%= @user&.email %></strong> 宛に送信しました。</p>
      <p class="mb-6">メール内のリンクをクリックすると、この画面が自動で更新され、登録が完了します。</p>
      <div data-confirmation-target="message" class="notice"></div>
    </div>
  </div>
</div>
```

### 文法レベルの解説
- `<%= ... %>` — ERB の出力タグ。Ruby 式を評価し、結果を HTML に埋め込む。`<%# ... %>` はコメント（HTML に出力されない）。
- `@waiter_sig` `@user` — コントローラーのアクション（`confirm_wait`）でセットしたインスタンス変数。ビューで自動参照できる。
- `@user&.id` の `&.` — **ぼっち演算子**。`@user` が `nil` ならメソッド呼び出しをせず `nil` を返す。
- `data-controller="confirmation"` — Stimulus の命名規則。「この要素は `confirmation_controller.js` に結び付ける」という指示。
- `data-confirmation-waiter-sig-value="..."` — Stimulus の値API。JS 側で `this.waiterSigValue` として読める。
- `data-turbo-permanent` — Turbo（Rails の SPA 的な仕組み）の属性。ページ遷移時にこの要素を保持させる指示。

### 初心者向け補足（用語）
- **Stimulus** — HTML の属性から JavaScript の挙動を接続する軽量フレームワーク。「HTML 側で `data-controller`, `data-action`, `data-target` を宣言 → JS 側でクラスを書く」という役割分担。
- **Turbo** — ページ遷移を高速化する仕組み（Rails 7 標準）。本機能では WebSocket で受け取ったデータを画面に反映する用途で使う。

### 2026年4月16日 → 4月21日 の変更点
- レイアウトを `profiles/show` を基準に統一（Tailwind CSS の `container`, `flex`, `md:w-2/3` 等を使った中央寄せレイアウト）。
- 不要なデバッグ用 `<p>` タグ（`data-confirmation-user-id-value=...`を表示していた）と、未使用の `turbo_stream_from` コメントを削除。
- 役割ベースの責務分離（待機メッセージと通知欄）が明確になった。

---

## ④ `app/javascript/controllers/confirmation_controller.js`

### 目的と処理内容
待機タブ側の Stimulus コントローラー。

1. AccountConfirmationChannel を `waiter_sig` 付きで購読
2. サーバから `{status:"confirmed", handoff_token}` を受信
3. `POST /auth/handoff` でセッションログインを成立させる
4. ユーザー情報の変更画面（`/profile/edit?from=confirmation`）へフルページ遷移

### 該当コード
```javascript
import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
    static targets  = [ "message" ]
    static values   = { waiterSig: String }

    connect()    { this.subscribe() }
    disconnect() { this.unsubscribe() }

    subscribe() {
        this.subscription = consumer.subscriptions.create(
            { channel: "AccountConfirmationChannel", waiter_sig: this.waiterSigValue },
            {
                received: async (data) => {
                    if (data?.status !== "confirmed" || !data?.handoff_token) return
                    await this.performHandoff(data.handoff_token)
                }
            }
        )
    }

    async performHandoff(handoffToken) {
        const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
        const res = await fetch("/auth/handoff", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken
            },
            credentials: "same-origin",
            body: JSON.stringify({ token: handoffToken })
        })
        if (!res.ok) { console.warn("handoff failed:", await res.text()); return }
        // ログインできたら、ユーザー情報の変更画面へ移る
        // （/profile/edit は登録の直後と通常の変更の両方で使うので、?from=confirmation で見分ける）
        window.location.assign("/profile/edit?from=confirmation")
    }
}
```

### 文法レベルの解説
- `static values = { waiterSig: String }` — Stimulus の仕組みで、HTML の `data-confirmation-waiter-sig-value="..."` を `this.waiterSigValue` として型付きで読めるようにする。
- `connect()` / `disconnect()` — Stimulus のライフサイクルメソッド。要素が DOM に入ったとき・外れたときに自動で呼ばれる。
- `consumer.subscriptions.create(channelParams, callbacks)` — ActionCable クライアント API。第1引数でどのチャンネルに何を渡すか、第2引数で受信時などのコールバックを指定。
- `received: async (data) => { ... }` — **アロー関数**。`this` がクラスインスタンスを指すので、`this.performHandoff` を呼べる。`async` が付いているので内部で `await` が使える。
- `data?.status !== "confirmed"` — **オプショナルチェーン**。`data` が `null`/`undefined` のときはエラーにせず `undefined` を返す。
- `fetch(...)` — ブラウザ標準の HTTP リクエスト API。
- `credentials: "same-origin"` — 同一オリジンのリクエストには Cookie を送る指示。セッション Cookie が不可欠なのでこの指定が必要。
- `window.location.assign(url)` — 指定 URL へフルページ遷移（ブラウザ履歴に残る）。

### 初心者向け補足（用語）
- **Stimulus のターゲット/バリュー** — HTML の `data-` 属性で JS と値を受け渡す規約。`data-[controller]-target="[name]"` → `this.[name]Target`、`data-[controller]-[key]-value="..."` → `this.[key]Value`。
- **CSRF トークン** — Rails のフォーム送信で自動付与される「その人のセッションと紐付いた秘密値」。これが一致しないと POST が弾かれる。`<meta name='csrf-token' content="...">` から取り出す。
- **非同期（async/await）** — 処理の完了を待つ書き方。Promise ベースの処理を同期的に書けるようにする糖衣構文。

### 2026年4月16日 → 4月21日 の変更点
- 200行近くあったコメントアウトの履歴コードを一掃し、**現行ロジックに集約**。
- `received` コールバック内に直書きだった `fetch` を **`performHandoff` メソッドとして切り出し**、責務を分離。
- `connected` / `disconnected` ログを削除（本番で騒がしいので）。
- `if (res.ok) { ... } else { ... }` のネストを **早期 return** で解消し、読みやすく整理。
- `console.log` の装飾文字（○ ● ☆ など）を撤廃し、必要最小限の `console.warn` のみ残す。

### その後の変更
- ログインできた後の移り先を、ユーザーのページ（`/users/:id`）から、ユーザー情報の変更画面（`/profile/edit?from=confirmation`）に変えた。登録の直後に、姓名・住所などを続けて入れてもらうため。
- 移り先に user id が要らなくなったので、応答の JSON の `user_id` を読むのをやめ、画面から user id を受け取る `userId` の値（`data-confirmation-user-id-value`）も外した。

---

## ⑤ `app/javascript/channels/consumer.js`

### 目的と処理内容
ActionCable の「コンシューマ（クライアント側の WebSocket 接続オブジェクト）」を作るだけのファイル。全チャンネル共通で使う。

### 該当コード
```javascript
import { createConsumer } from "@rails/actioncable"
export default createConsumer()
```

### 文法レベルの解説
- `createConsumer()` — 引数なしで呼ぶと、サーバが提供する `<meta name="action-cable-url" content="...">` からエンドポイントを自動取得する。URL を直指定する必要がなくなり、開発・本番で同じコードが動く。
- `export default ...` — このモジュールの既定エクスポート。他ファイルから `import consumer from "channels/consumer"` で受け取れる。

### 初心者向け補足（用語）
- **Consumer（コンシューマ）** — ActionCable における「WebSocket 接続を1本だけ張って、その上に複数のチャンネル購読を乗せる」ためのオブジェクト。アプリ内で1つに統一するのが定石。

### 2026年4月16日 → 4月21日 の変更点
- このファイル自体は変更なし（サインアップリファクタのスコープ外）。

---

## ⑥ `app/channels/application_cable/connection.rb`

### 目的と処理内容
WebSocket 接続ごとのベースクラス。クライアントがつないできたとき、サーバ側でどう受け入れるかを決める。

### 該当コード
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = env['warden']&.user(:user)
    end
  end
end
```

### 文法レベルの解説
- `identified_by :current_user` — 「この接続を識別するキーとして `current_user` を使う」という宣言。同一ユーザーの複数接続を区別できる。
- `env['warden']&.user(:user)` — Devise が利用する認証ミドルウェア Warden のオブジェクトを取得し、ログイン中ユーザーを拾う。`&.` により `env['warden']` が `nil` でもエラーにならない。
- 未ログイン接続を `reject_unauthorized_connection` で拒否していない — **メール確認の待機中はまだログインしていない**ため、WebSocket 接続は許可する必要がある。

### 初心者向け補足（用語）
- **Warden** — Rack 上で動く認証フレームワーク。Devise の中身。「誰がログイン中か」の判定を担う。
- **ActionCable の接続 vs 購読** — 接続（Connection）は WebSocket そのもの。その中にチャンネル購読（Channel）が複数乗る。認証は接続で1回、認可は各チャンネルで別々にかけるのが一般的。

### 2026年4月16日 → 4月21日 の変更点
- 以前：`find_verified_user` という独自メソッドで **署名付き Cookie `ws_user_id` からのフォールバック**をしていた + デバッグ用の `log_ws_snapshot` が書かれていた。
- 現在：**接続認証を最小化**。Warden からユーザーを拾うだけに簡素化。認証の本体（誰に通知を送るかの判定）は `AccountConfirmationChannel` で `waiter_sig` を検証して行う設計に寄せた。
- **考え方**：「Connection は広く受け入れる／Channel で厳密に検証する」というレイヤー分担を明確にした。Connection で複雑な認証を書くと、未ログインユーザー（まさに待機中）を誤って弾いてしまう。

---

## ⑦ `app/channels/account_confirmation_channel.rb`

### 目的と処理内容
メール確認完了の「通知」を待機タブへリアルタイム配信するチャンネル。
- `subscribed` で `waiter_sig` を検証 → 本人の `jti` 単位でプライベートストリーム購読。
- レース対策：`subscribe` より先にメール確認が走っていた場合、保留中の handoff を即時 `transmit` で届ける。

### 該当コード
```ruby
class AccountConfirmationChannel < ApplicationCable::Channel
  def subscribed
    uid, jti = verify_waiter_sig(params[:waiter_sig])
    return reject unless uid && jti

    stream_from "confirmation_wait:#{jti}"

    pending_token = WaiterRegistry.take_pending_handoff(uid)
    if pending_token.present?
      transmit({
        status: "confirmed",
        message: "メールアドレスの確認が完了しました。",
        handoff_token: pending_token
      })
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    reject
  end

  private

  def verify_waiter_sig(sig)
    return [nil, nil] if sig.blank?
    data = Rails.application.message_verifier(:waiter).verify(sig, purpose: :waiter)
    uid = data["uid"] || data[:uid]
    jti = data["jti"] || data[:jti]
    exp = (data["exp"] || data[:exp]).to_i
    return [nil, nil] if uid.blank? || jti.blank? || exp <= 0 || Time.at(exp) <= Time.current
    [uid, jti]
  end
end
```

### 文法レベルの解説
- `subscribed` — ActionCable の規約メソッド。クライアントが購読してきたタイミングで呼ばれる。
- `uid, jti = verify_waiter_sig(...)` — **多重代入**。配列を返すメソッドから2つの変数へ一気に代入。
- `return reject unless uid && jti` — 条件を満たさなければ `reject`（購読拒否）を返して終了する定型句。
- `stream_from "confirmation_wait:#{jti}"` — この名前（`jti` を含むので他人には推測できない）の配信ストリームを購読する。サーバ側で `ActionCable.server.broadcast("confirmation_wait:#{jti}", ...)` と送ると、このクライアントだけが受け取れる。
- `transmit({...})` — 今 subscribe したクライアントへだけ即時メッセージを送る。ブロードキャスト（全員に送る）ではない。
- `rescue ActiveSupport::MessageVerifier::InvalidSignature` — 署名不正はエラーではなく「拒否」として扱う。

### 初心者向け補足（用語）
- **チャンネル（Channel）** — 接続の上に乗る「論理的な通信路」。1つの接続で複数チャンネルを購読できる。
- **ストリーム（stream_from）** — チャンネル内の細かいトピック名。特定の `stream_from` に `broadcast` することでピンポイント配信できる。
- **`transmit` vs `broadcast`** — `transmit` は「今サーバとつながっているこの1人」に送る。`broadcast` は「指定ストリームを購読している全員」に送る。
- **レースコンディション** — タイミング依存で順序が逆転する問題。本機能なら「メール確認の方が早く終わってしまい、待機タブがまだ購読前だった」場合に通知を取りこぼすことを指す。

### 2026年4月16日 → 4月21日 の変更点
1. **`subscribed` メソッドが大幅にスリム化**。検証ロジックを `verify_waiter_sig` に切り出して責務分離。
2. **レース対策の追加（重要）**：`WaiterRegistry.take_pending_handoff(uid)` で保留トークンを取り出し、あれば即時 `transmit` する処理を新設。「メール確認の方が先に走った」ケースで通知を取りこぼさなくなった。
3. 冗長な debug ログを削除。
4. `rescue => e` の巨大 catch を廃止し、`InvalidSignature` のみに絞って reject する形に。

---

## ⑧ `app/services/waiter_registry.rb`

### 目的と処理内容
「待機タブ」関連の一時ストレージ（Redis 優先・なければ Rails.cache）。
1. **ユーザーID → 最新の待機用 `jti`** を短期間（30分）保存／取得。
2. **保留ハンドオフトークン**（`pending_handoff`）を uid ごとに5分間だけ保存／1回限りで取り出し。

### 該当コード（主要部分）
```ruby
class WaiterRegistry
  KEY_FMT = "waiter:latest:%{uid}"
  PENDING_FMT = "waiter:pending:%{uid}"

  class << self
    def set_latest_jti_for(uid, jti, ttl: 30.minutes)
      write_backend(KEY_FMT % { uid: uid }, jti, ttl: ttl)
    end

    def latest_jti_for(uid)
      read_backend(KEY_FMT % { uid: uid })
    end

    def set_pending_handoff(uid, token, ttl: 5.minutes)
      write_backend(PENDING_FMT % { uid: uid }, token, ttl: ttl)
    end

    def take_pending_handoff(uid)
      key = PENDING_FMT % { uid: uid }
      value = read_backend(key)
      delete_backend(key) if value
      value
    end

    private

    def write_backend(key, value, ttl:)
      if redis_available?
        redis.set(key, value, ex: ttl.to_i)
      else
        cache.write(key, value, expires_in: ttl)
      end
    rescue => e
      Rails.logger.warn "[WaiterRegistry] write failed: #{e.class} #{e.message}"
      nil
    end
    # read_backend / delete_backend も同様
  end
end
```

### 文法レベルの解説
- `class << self ... end` — **特異クラス**。この中で定義したメソッドは「クラスメソッド（`WaiterRegistry.set_latest_jti_for` など）」になる。`self.foo` を並べるのと同義だが、まとめて書けて見通しが良い。
- `"waiter:latest:%{uid}" % { uid: 42 }` — 文字列への名前付きフォーマット。`"waiter:latest:42"` になる。`sprintf` と同じ仕組み。
- キーワード引数 `ttl: 30.minutes` — 呼び出し側で `ttl: 10.minutes` のように明示できる。省略時はデフォルト値。
- `rescue => e` のメソッド末尾記法 — メソッド全体を try とみなし、例外を `e` にバインドして補足できる。
- `take_pending_handoff` の `if value` — 読み出せたときだけ削除。取得と同時に消すことで「使い捨て」を実現（二重発火防止）。

### 初心者向け補足（用語）
- **サービスクラス** — コントローラーからもモデルからも呼べる、「独立した処理の単位」を入れるクラス。`app/services/` に置くのが Rails のよくある慣例。
- **Redis** — インメモリのキー・バリューストア。高速で TTL（自動失効）が使える。本番の一時ストアに最適。
- **Rails.cache** — Rails 組み込みのキャッシュ API。バックエンドを差し替えられる（MemoryStore / RedisStore / NullStore など）。
- **NullStore** — 何もしないキャッシュ。開発モードで `config.cache_classes = false` のときの既定。キャッシュを入れても即消える。

### 2026年4月16日 → 4月21日 の変更点
- **保留ハンドオフ（pending_handoff）を新設**：`set_pending_handoff` / `take_pending_handoff` を追加。レース対策の要。
- 初期実装（2025年10月10日時点）にあった **Redis 直 glue のコメントアウト残骸を削除**。
- 書き込み／読み出し／削除を `write_backend` / `read_backend` / `delete_backend` の3関数に統合（DRY）。
- **考え方**：「Channel 側で pending_handoff を消費する側」が導入されたので、本サービスも「保存＋取り出し（単発使用）」の API を対称で揃えた。

---

## ⑨ `app/controllers/users/confirmations_controller.rb`

### 目的と処理内容
メール確認リンク（GET /users/confirmation?confirmation_token=xxxx）を受け取り、
1. Devise 標準の `confirm_by_token` でメール確認済みに切り替える。
2. **この新規タブでログインを成立**させる。
3. 待機タブに向けて **`handoff_token`（引換券）を ActionCable で通知**する（subscribe前なら pending_handoff に保留保存）。

### 該当コード
```ruby
class Users::ConfirmationsController < Devise::ConfirmationsController
  include Devise::Controllers::Rememberable

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?
    return handle_confirmation_failure unless resource.errors.empty?

    sign_in_confirmed_user
    broadcast_handoff_to_waiter

    flash[:page] = { title: "確認", message: "メールアドレスの確認が完了しました。", type: "success" }
    respond_with_navigational(resource) do
      redirect_to after_confirmation_path_for(resource_name, resource), status: :see_other
    end
  end

  protected
  def after_confirmation_path_for(_resource_name, _resource)
    page_mail_check_path
  end

  private

  def handle_confirmation_failure
    # 既に確認済みのトークンで再アクセスされた（メールの先読みやスキャナが先に踏んだ）
    if resource.confirmed? && resource.persisted?
      sign_in_confirmed_user
      broadcast_handoff_to_waiter
      flash[:page] = { title: "確認", message: "メールアドレスは既に確認済みです。", type: "success" }
      respond_with_navigational(resource) do
        redirect_to after_confirmation_path_for(resource_name, resource), status: :see_other
      end
      return
    end

    flash[:page] = { title: "通知", message: "リンク無効または期限切れです。", type: "alert" }
    respond_with_navigational(resource.errors, status: :unprocessable_entity) do
      redirect_to page_mail_check_path
    end
  end

  def sign_in_confirmed_user
    return if user_signed_in? || !resource.active_for_authentication?
    sign_in(:user, resource)
    request.env['devise.skip_timeout'] = true
  end

  def broadcast_handoff_to_waiter
    payload = { uid: resource.id, jti: SecureRandom.hex(16), exp: 5.minutes.from_now.to_i }
    token = Rails.application.message_verifier(:confirm_handoff)
                .generate(payload, purpose: :confirm_handoff)

    WaiterRegistry.set_pending_handoff(resource.id, token, ttl: 5.minutes)

    jti = WaiterRegistry.latest_jti_for(resource.id)
    if jti.present?
      ActionCable.server.broadcast(
        "confirmation_wait:#{jti}",
        { status: "confirmed", message: "メールアドレスの確認が完了しました。", handoff_token: token }
      )
    else
      Rails.logger.info "[Confirmations#show] waiter 未検出 user_id=#{resource.id}"
    end
  end
end
```

### 文法レベルの解説
- `resource_class.confirm_by_token(token)` — Devise Confirmable モジュールが提供するクラスメソッド。トークンに合う User を探し、確認済みに更新する。失敗時は `errors` が入った空レコードを返す。
- `yield resource if block_given?` — このアクションを block 付きで呼ばれたときのフック（Devise 互換のため残す）。通常呼び出しでは無視される。
- `respond_with_navigational(resource) do ... end` — Devise 提供の「ナビゲーショナルなレスポンス（HTML リダイレクト）」を生成するヘルパー。HTML とそれ以外のフォーマットで分岐できる。
- `redirect_to ..., status: :see_other` — HTTP 303 を明示。Turbo/Hotwire 環境で POST→リダイレクトを安定して GET に切り替える。
- `ActionCable.server.broadcast(stream_name, data)` — サーバからブロードキャスト。指定ストリームを `stream_from` で購読しているクライアントに届く。
- `Rails.application.message_verifier(:confirm_handoff).generate(payload, purpose: :confirm_handoff)` — 短期の「引換券」を作る。受け取り側（`AuthHandoffsController`）が `verify` で検証。

### 初心者向け補足（用語）
- **Devise Confirmable** — メール確認機能を提供する Devise のモジュール。`confirmation_token` / `confirmed_at` カラムを使う。
- **`sign_in` vs `bypass_sign_in`** — 前者は Warden のフックを通常フローで走らせるサインイン、後者はフックをバイパスして直接セッションに入れる（Timeoutable などの副作用を避けたい時に使う）。
- **HTTP 303 See Other** — 「この URL に GET で再取得してね」を表すリダイレクトステータス。POST のレスポンスで 302 の代わりに 303 を返すのが望ましい場面で使う。

### 2026年4月16日 → 4月21日 の変更点（最も劇的）
以前は **386 行** あったファイルが **96 行** に圧縮された。主な変更：
1. **失敗処理を `handle_confirmation_failure` に切り出し**。早期 return で本流を短縮。
2. **`sign_in_confirmed_user` に切り出し**。`bypass_sign_in`／`sign_in`／各種フラグ更新の迷いコードを整理し、正規フロー（`sign_in(:user, resource)` + `devise.skip_timeout`）に一本化。
3. **`broadcast_handoff_to_waiter` を新設**し、そこで「まず pending_handoff に保留保存 → 次に jti があれば broadcast」という順序に変更。以前は jti が無い時に `confirmation_user_#{id}` という旧ストリーム名に broadcast する**デッドフォールバック**があった（当該ストリームを誰も subscribe していないので無意味）。現在は **`pending_handoff` が代役**になり、確実に届く構造。
4. 巨大なコメントアウトブロック（過去に試した remember_me / forget_me / `last_request_at` 手動更新 / `ws_user_id` Cookie 発行など）を全撤去。
5. **考え方**：「*正常系と異常系を分け、各処理を意味のある private メソッドに閉じ込める*」という整理方針。試行錯誤の痕跡はコード本体からは取り除く（公開版のリポジトリには、それ以前の履歴は含めていない）。

### その後の変更
- 既に確認済みのトークンで再アクセスされたとき、以前は plain text（`This email address has already been confirmed.`）を返していた。Gmail・Outlook のリンクの先読みやセキュリティスキャナが本人より先にリンクを踏むと、本人のクリックがこの分岐に入り、「失敗」に見えてしまう。そこで、正常系と同じく待機タブへ引換券を送り、確認完了の画面へ導くようにした（何度踏んでも同じ結果になる＝冪等）。

---

## ⑩ `app/controllers/auth_handoffs_controller.rb`

### 目的と処理内容
「引換券（handoff_token）」を受け取って、**呼び出し元のタブ（＝待機タブ）のセッションに対してログイン**を成立させる専用エンドポイント。

### 該当コード
```ruby
class AuthHandoffsController < ApplicationController
  # 署名付き handoff_token で本人であることを確かめるので、セッションの CSRF トークンには頼らない
  skip_forgery_protection

  def create
    token_param = params[:token].presence || params.dig(:auth_handoff, :token)
    unless token_param.present?
      render json: { ok: false, error: "missing token" }, status: :bad_request and return
    end

    data = Rails.application.message_verifier(:confirm_handoff)
                .verify(token_param, purpose: :confirm_handoff)

    uid = data["uid"] || data[:uid]
    jti = data["jti"] || data[:jti]
    exp = data["exp"] || data[:exp]
    exp_i = exp.to_i if exp

    if uid.blank? || jti.blank? || !(exp_i && exp_i > 0)
      render json: { ok: false, error: "invalid token payload" }, status: :unauthorized and return
    end

    raise "expired" if Time.at(exp_i) <= Time.current

    if UsedJtiStore.used?(jti)
      render json: { ok: false, error: "replayed" }, status: :unauthorized and return
    end
    UsedJtiStore.mark!(jti, ttl: 10.minutes)

    user = User.find(uid)
    bypass_sign_in(user)
    flash.discard(:page)
    render json: { ok: true, user_id: user.id }
  rescue ActiveSupport::MessageVerifier::InvalidSignature, RuntimeError => e
    Rails.logger.warn "[AuthHandoffs#create] token verify failed: #{e.class}: #{e.message}"
    render json: { ok: false }, status: :unauthorized
  end
end
```

### 文法レベルの解説
- `skip_forgery_protection` — このコントローラーだけ CSRF 検証を外す。Devise はサインインのときに CSRF トークンを作り直す（`clean_up_csrf_token_on_authentication`）ので、別のタブでメール確認のサインインが走ると、待機タブが持っている CSRF トークンが無効になり、`POST /auth/handoff` が 422（`InvalidAuthenticityToken`）で止まる。ここは署名付きトークン（期限つき・jti の使い回し不可）で本人であることを確かめているので、CSRF トークンが無くても偽造はできない。
- `params[:token].presence || params.dig(:auth_handoff, :token)` — `presence` は「空白なら nil を返す」。JSON なら `{ token: "..." }` が、form なら `auth_handoff[token]=...` が来るのでどちらにも対応。
- `render json: {...}, status: :bad_request and return` — ここでレスポンスを返し終了する定型句。`and return` はメソッドを即終了させる Ruby 的な書き方。
- `bypass_sign_in(user)` — Devise のメソッド。フックを通さずにこのリクエストのセッションへユーザーを入れる。ここが**「別タブのログイン成立」の肝**。
- `rescue ActiveSupport::MessageVerifier::InvalidSignature, RuntimeError => e` — 複数の例外クラスをまとめて捕捉。

### 初心者向け補足（用語）
- **CSRF（クロスサイトリクエストフォージェリ）** — 第三者サイトから強制的に POST される攻撃。Rails は `authenticity_token` の一致を要求することで防いでいる。このエンドポイントでは、代わりに handoff_token が同じ役目を果たす（第三者は正しい handoff_token を作れない）。
- **リプレイ攻撃** — 1回使われた正規のトークンを盗んで、もう一度使う攻撃。ここでは `UsedJtiStore` で1回使った `jti` を記録し、2回目は拒否する。

### 2026年4月16日 → 4月21日 の変更点
- このファイルは、このリファクタリングでは**実質的に変更されていない**（2025年9月22日の作成時から継続）。

### その後の変更
- `protect_from_forgery with: :exception` をやめ、`skip_forgery_protection` にした。別のタブでのサインインで待機タブの CSRF トークンが無効になり、ログインの引き継ぎが 422 で止まっていたため（理由は上の「文法レベルの解説」）。

---

## ⑪ `app/services/used_jti_store.rb`

### 目的と処理内容
「このトークン（JTI = JSON Web Token ID）はもう使った」ことを短期間（10分）記録するストア。**リプレイ攻撃防止**に使う。Redis 優先、なければ Rails.cache にフォールバック。

### 該当コード
```ruby
class UsedJtiStore
  KEY_FMT = "used_jti:%{jti}"

  class << self
    def used?(jti)
      key = KEY_FMT % { jti: jti }
      if redis_available?
        redis.exists?(key)
      else
        cache.exist?(key)
      end
    rescue => e
      Rails.logger.warn "[UsedJtiStore] used? failed: #{e.class} #{e.message}"
      false
    end

    def mark!(jti, ttl: 10.minutes)
      key = KEY_FMT % { jti: jti }
      if redis_available?
        redis.set(key, 1, ex: ttl.to_i)
      else
        cache.write(key, true, expires_in: ttl)
      end
      true
    rescue => e
      Rails.logger.warn "[UsedJtiStore] mark! failed: #{e.class} #{e.message}"
      false
    end

    private
    def redis_available?; ENV['REDIS_URL'].present?; end
    def redis; @redis ||= Redis.new(url: ENV['REDIS_URL']); end
    def cache
      if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
        @local_cache ||= ActiveSupport::Cache::MemoryStore.new
      else
        Rails.cache
      end
    end
  end
end
```

### 文法レベルの解説
- `redis.exists?(key)` — Redis 4 系以降は Boolean を返す（旧バージョンは件数を返した）。互換のため `?` 付き API を使う。
- `redis.set(key, 1, ex: ttl.to_i)` — 値は何でも良く、**「あれば使用済み」**という存在ベースの判定。`ex:` で秒単位の TTL。
- `@redis ||= Redis.new(...)` — **メモ化**。初回のみインスタンス生成し、以後は同じ接続を使い回す。
- `if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)` — 開発モードでキャッシュ無効時に NullStore が使われる。その場合は**ローカル MemoryStore にすり替え**、最低限の動作を保証。
- `rescue => e` の大域補足 — ここはサービスの可用性を優先したい処理なので、失敗しても `false` を返して処理を継続。

### 初心者向け補足（用語）
- **JTI（JWT ID）** — トークンの一意識別子。リプレイ防止やトークン失効管理に使う。本アプリでは `SecureRandom.hex(16)` で生成。
- **TTL（Time To Live）** — キーの生存時間。Redis の `ex:` や Rails.cache の `expires_in:` で指定。自動失効してくれるので掃除不要。
- **メモ化（memoization）** — 計算コストの高い結果をインスタンス変数にキャッシュする書き方。

### 2026年4月16日 → 4月21日 の変更点
- このファイルは、このリファクタリングの対象外（変更なし）。

---

## ⑫ `app/controllers/pages_controller.rb`

### 目的と処理内容
「メール確認の通知ページ（`/page/mail_check`）」を表示するコントローラー。確認タブ（メールリンクを踏んだ新規タブ）がこのページに遷移し、「確認が完了しました」のメッセージを表示して閉じられる想定。

### 該当コード
```ruby
class PagesController < ApplicationController
  layout 'page'

  def mail_check
    request.env['devise.skip_timeout'] = true

    page = (flash[:page] || {}).with_indifferent_access
    @title   = page[:title]   || params[:title]   || "== 通知 =="
    @message = page[:message] || params[:message] || ""
    @type    = page[:type]    || params[:type]    || "info"

    flash.discard(:page)
  end
end
```

### 文法レベルの解説
- `layout 'page'` — このコントローラーのすべてのビューは `app/views/layouts/page.html.erb` を使う。通常のアプリケーションレイアウトとは別のミニマル用。
- `request.env['devise.skip_timeout'] = true` — このリクエストだけ Devise Timeoutable の判定をスキップ。確認直後は「前回アクセスが古い」と誤判定されやすいため。
- `(flash[:page] || {}).with_indifferent_access` — `flash[:page]` が `nil` なら空ハッシュ。`with_indifferent_access` で **文字列キー／シンボルキーのどちらでもアクセスできる**ように変換。
- `flash[:page] = { ... }` ではなく `flash[:page] || params[...]` の多段フォールバックで柔軟にタイトルを決定。
- `flash.discard(:page)` — この1リクエストで flash を消費し、次リクエストに持ち越さない。

### 初心者向け補足（用語）
- **flash** — リクエストをまたぐ一時的な小さなメッセージ置き場。リダイレクト先で1回だけ取り出せる。
- **HashWithIndifferentAccess** — Rails の拡張ハッシュ。`h[:foo]` と `h["foo"]` が等価になる。params や flash を扱うときの定番。
- **Timeoutable** — Devise の「一定時間操作がないと自動ログアウト」モジュール。便利だが誤判定しやすいので `devise.skip_timeout` でピンポイント回避する。

### 2026年4月16日 → 4月21日 の変更点
- このファイルは、このリファクタリングの対象外（変更なし）。

---

## まとめ：リファクタリングの基本思想

2026年4月21日のリファクタリング（Claude Code による）は、以下の軸で整理できる。

### 1. セキュリティの強化
- **URL に `:id` を露出しない**（`confirm_wait?id=` → `confirm_wait?sig=`）。第三者による他人情報の覗き見を封じる。
- **`correct_user` の比較バグを修正**：`@user == current_user` → `current_user.id.to_s == params[:id].to_s`。他人IDでの destroy を防止。

### 2. レースコンディション対策
- `WaiterRegistry.set_pending_handoff` / `take_pending_handoff` を追加。
- `AccountConfirmationChannel#subscribed` で保留トークンを即時 `transmit`。
- `Confirmations#show` は「broadcast + pending_handoff」を両方行うので、subscribe 順序が逆でも届く。

### 3. 責務の分離とコード圧縮
- `ConfirmationsController`: 386行 → 96行。`show` を3つの private メソッド（`handle_confirmation_failure` / `sign_in_confirmed_user` / `broadcast_handoff_to_waiter`）に分解。
- `RegistrationsController#confirm_wait`: 検証ロジックを `verify_confirm_wait_sig` に切り出し。
- `AccountConfirmationChannel#subscribed`: 検証ロジックを `verify_waiter_sig` に切り出し。
- `confirmation_controller.js`: 受信コールバックから `performHandoff` を分離。

### 4. 試行錯誤の痕跡を削除
- 大量のコメントアウト（過去の `remember_me` / `forget_me` / `last_request_at` 手動更新 / `ws_user_id` 署名 Cookie / `/auth/ping` リトライループなど）を全撤去。
- 履歴は git log に任せ、コード本体は **現行ロジックだけが残る状態** へ。
- 冗長な `console.log` / `Rails.logger.debug` を削除し、本当に必要な警告・情報ログだけを残す。

### 5. レイヤー分担の明確化
- `ApplicationCable::Connection`: 「広く受け入れる」最小構成。
- `AccountConfirmationChannel`: 「`waiter_sig` で厳密に検証」して `jti` ストリームへ参加。
- `AuthHandoffsController`: 「引換券検証 + リプレイ防止 + `bypass_sign_in`」のみに集中。
- `WaiterRegistry` / `UsedJtiStore`: 「ストレージバックエンド（Redis/Cache）」を吸収する層を独立化。

---

## Rails 初心者への補足事項

### A. ActionCable の使い分け
- **接続（Connection）** ＝ WebSocket そのもの。1ブラウザ1本。
- **チャンネル（Channel）** ＝ 接続の上の論理トピック。複数購読できる。
- **ストリーム（stream_from "xxx"）** ＝ チャンネル内の細かいトピック。`broadcast("xxx", data)` で送ると、その "xxx" を `stream_from` している購読者全員に届く。
- `transmit` は「今接続しているこの1人」へ。subscribe の瞬間に個別送信したいときに使う。

### B. `message_verifier` と JWT の違い
- Rails の `Rails.application.message_verifier(:purpose)` は **同じアプリ内でしか検証できない署名器**（秘密鍵は `secret_key_base`）。他サービスから検証する必要がなければ、JWT より簡単で安全。
- `purpose:` は「用途タグ」。同じ秘密鍵で作った別用途トークンを流用されないためのラベル。

### C. Redis / Cache の使い分け
- **本番**: `REDIS_URL` を `.env` に設定すれば `WaiterRegistry` / `UsedJtiStore` は自動で Redis を使う。
- **開発**: Redis が無くても動くよう、`Rails.cache` または `MemoryStore` にフォールバック。ただしプロセス間で共有されないので、本番想定のテストは Redis 起動が望ましい。

### D. Stimulus の `data-*-value` 命名規則
- HTML: `data-[controller]-[key]-value="..."`
- JS: `static values = { [camelKey]: Type }` → `this.[camelKey]Value`
- 例：`data-confirmation-waiter-sig-value` ↔ `this.waiterSigValue`
- **ケバブケース → キャメルケース** の変換が自動で行われる。

### E. 「タブをまたぐ自動ログイン」という要件の本質
- 普通の Devise confirmable では「メール確認を踏んだタブでログインする」のみ。
- 本アプリはそれに加え、**「サインアップしたタブ（待機タブ）の方でも自動的にログイン状態にして、画面を切り替える」**ことを要求している。
- この要件は、WebSocket（ActionCable）+ 短命トークン（handoff_token）+ 一時ストア（Redis）の組み合わせで実現している。
- 仕組みが複雑に感じても、各ファイルは「1つの責務」を担っているだけ。**時系列フロー（`docs/signup_flow_guide.md`）と各ファイルの役割の対応**が取れれば理解は進む。

### F. 参考ドキュメント
- 時系列フローの全体像は `docs/signup_flow_guide.md`（2026年4月18日作成）を参照。
- テストコードは `spec/channels/account_confirmation_channel_spec.rb` / `spec/requests/auth_handoffs_spec.rb` / `spec/requests/users/confirmations_spec.rb` / `spec/requests/users/registrations_spec.rb` / `spec/services/waiter_registry_spec.rb` にある。
