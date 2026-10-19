# CLAUDE.md

このファイルは、リポジトリで作業する Claude Code (claude.ai/code) へのガイダンスを提供します。

## プロジェクト概要

- Twitter のようなソーシャルマイクロポストアプリ。
- ユーザーは登録、マイクロポスト（140文字＋画像）の投稿、相互フォローが可能である。
- ActionCable によるリアルタイム更新に対応している（メール確認を待っているタブを、確認の完了と同時にログインさせる）。

## 技術スタック

- 言語: Ruby 3.3.7
- フレームワーク: Rails 7.2
- DB: PostgreSQL 17（但し、テスト環境は SQLite3）
- テストフレームワーク: RSpec
- 認証: Devise 4.9（Google OAuth2 含む）
- フロントエンド: Hotwire（Turbo + Stimulus）、ActionCable、importmap
- CSS: Tailwind CSS
- IDE: RubyMine

## アプリの起動

### 開発環境

Docker で動かす（`Dockerfile.local`・`docker-compose.local.yml`）。ホストに Ruby・PostgreSQL は要らない。

```bash
cp .env.example .env          # COMPOSE_FILE=docker-compose.local.yml が入っている。DB_PASSWORD は手元用の値を入れる
docker compose build
docker compose run --rm app bundle install
docker compose up -d          # app（bin/dev：Rails ＋ Tailwind の watch）と db（PostgreSQL 17）
docker compose exec app bin/rails db:prepare
```

アクセス先：http://localhost:3000（開発用のメールの受信箱は http://localhost:3000/letter_opener）

- `.env` の `COMPOSE_FILE` により、`docker compose` は開発用の構成を使う。本番用の `docker-compose.yml` を誤って使わない。
- ポートは `127.0.0.1` だけで開く。ほかのアプリと同時に動かすときは `.env` の `APP_PORT`・`DB_PORT` を変える。
- 開発では Redis を使わない（Action Cable は `async`、セッションは Cookie）。

### テスト環境

app コンテナの中で RSpec を実行する。テスト DB は SQLite3。

```bash
docker compose exec app bundle exec rspec                              # 全スペック
docker compose exec app bundle exec rspec spec/models/user_spec.rb     # 単一ファイル
docker compose exec app bundle exec rspec spec/models/user_spec.rb:42  # 行番号指定
```

- `app/assets/builds/tailwind.css` は Git に入っていない。`bin/dev` で起動していない（Tailwind の watch が動いていない）ときは、先に `bin/rails tailwindcss:build` を実行する（無いと画面を描くスペックが 500 で落ちる）。
- スペックの種類：`spec/models/`、`spec/requests/`、`spec/system/`（`driven_by(:rack_test)`。ブラウザは使わない）、`spec/channels/`、`spec/services/`、`spec/factories/`
- `spec/support/` 配下は `rails_helper.rb` で自動ロード。FactoryBot のメソッド（`build`、`create` など）は全スペックで直接使用可能。

### 本番環境

Nginx をリバースプロキシとして使用し、Docker 上で動作する（`Dockerfile`・`Dockerfile.db`・`docker-compose.yml`）。
サービス構成：`db`（PostgreSQL 17）、`redis`、`app`（Unix ソケット上の Rails/Puma）、`web`（Nginx）。環境変数は `.env.production`（見本は `.env.production.example`）。

```bash
docker compose -f docker-compose.yml build
docker compose -f docker-compose.yml up -d
docker compose -f docker-compose.yml exec app bundle exec rails db:migrate
```

## アーキテクチャ

### モデル

- **User** — Devise 認証。使用モジュール：`database_authenticatable`、`registerable`、`confirmable`、`trackable`、`omniauthable`（Google OAuth2）。カスタムフィールド：`first_name`、`last_name`、`kana`、`birthday`、`address`。Relationship 中間テーブルを介してマイクロポスト・フォロワー・フォロー中を持つ。
- **Micropost** — User に belongs_to。`content` は最大140文字、ActiveStorage で画像添付（`has_one_attached :image`）、デフォルトスコープは `created_at DESC` 順。
- **Relationship** — `follower_id` / `followed_id`（どちらも users の FK）を持つ中間テーブル。`user.following` と `user.followers` を実現する。

### 認証フロー

Devise のルーティングは `app/controllers/users/` 配下のカスタムコントローラーを使用：

- `Users::RegistrationsController` — 新規登録、確認待ち画面（`/users/confirm_wait?sig=...`。id は URL に載せず署名付きトークンで渡す）、メール・パスワードの独立編集画面（`/account/email/edit`、`/account/password/edit`）
- `Users::SessionsController` — ログイン・ログアウト
- `Users::ConfirmationsController` — メール確認。確認が済んだら、待っているタブへ引換券（handoff_token）を ActionCable で送る
- `Users::OmniauthCallbacksController` — Google OAuth2 コールバック
- `AuthHandoffsController` — 引換券を受け取り、待っていたタブのセッションでログインさせる（`POST /auth/handoff`）
- `ProfilesController` — ログイン中のユーザー自身のプロフィール（表示・編集 → 確認 → 保存）

サインアップからログインまでの流れは `docs/signup_flow_guide.md`（時系列）と `docs/signup_flow_code_commentary.md`（コードの解説）にまとめてある。

### 主要設定

- **セッション**：本番は Redis（`REDIS_URL` が必須）、開発は Cookie（`config/initializers/session_store.rb`、`config/initializers/redis.rb`）
- **一時ストア**：`app/services/waiter_registry.rb`・`used_jti_store.rb` は `REDIS_URL` があれば Redis、無ければ `Rails.cache`（NullStore なら MemoryStore）を使う
- **データベース**：開発・本番は PostgreSQL（接続先は `DATABASE_HOST` などの環境変数）、テスト環境は SQLite3
- **Puma**：本番は Unix ソケット `tmp/sockets/puma.sock` にバインド（Docker ボリューム経由で Nginx と共有）
- **メールプレビュー**：開発環境のみ LetterOpenerWeb を `/letter_opener` で使用。メールは Devise のメーラーが送る

## コーディング規約

### 基本ルール

- **インデントは半角スペース2つ**（Rails 標準）。タブ文字は使わない
- **不要になったコードは削除する**。
  - 修正履歴としてコメントアウトしたまま残さない（消したコードは Git の履歴に残る）。
- 秘密の値（パスワード・API キー・ホスト名など）はコードに書かず、環境変数から読む。手元の値は `.env` に置き、`.env.example` には名前だけを書く。

### コメントのルール

- **コメントは日本語**で書く。
- 以下の箇所には必ずコメントを添える：
  - クラス・メソッドの冒頭に「何をするか（1行）」を書く
  - 「なぜこう書いたか」が分かりにくい箇所は理由コメントを付ける
  - `before_action` や `validates` など、Rails 特有の構文（初心者には意味が分かりにくいため）
  - 条件分岐（`if` / `unless`）で、なぜその条件が必要なのかが自明でない箇所
- 以下の箇所は、必要に応じて当該コメントを添える
  - model: 業務ルールの理由、バリデーションの背景、callback の注意点
  - controller: 認可や分岐の理由、外部仕様との対応関係
  - service object: 入力、出力、副作用、失敗時の扱い
  - initializer / config: なぜこの設定が必要か、変えると何が壊れるか
- 日付や演習番号だけのメモは書かない（いつ変えたかは Git の履歴に残る）。

### モデル・コントローラーの記述順序

モデルは `include → 定数 → アソシエーション → バリデーション → コールバック → スコープ → メソッド → private` の順に統一する。

コントローラーは `before_action → アクション → private（ストロングパラメータ → 認可チェック）` の順に統一する。

- `before_action` には必ず `only:` で対象アクションを限定する
- `private` 以下のメソッドはインデントを追加しない（`private` と同じ深さで揃える）
- デバッグ用メソッドやログ出力は残さない

### ビュー（app/views/）

- ERB のコメントは `<%# コメント %>` を使う（`<%#= %>` は使わない）
- 複雑な条件分岐には日本語コメントで意図を補足する

### テスト（spec/）

**describe / context / it の使い分け：**

```ruby
RSpec.describe User, type: :model do
  describe 'バリデーション' do     # テスト対象の機能
    context 'nameが空の場合' do    # 前提条件
      it '無効であること' do       # 期待する結果
        user = build(:user, name: '')
        expect(user.valid?).to eq false
      end
    end
  end
end
```

- `describe` / `context` / `it` のラベルは日本語で書く
- `let` でテストデータを宣言し、`before` ブロックで事前処理を行う
- `create` は DB 保存が必要な場合のみ使い、不要なら `build` を使う

**ワンライナー記法と明示的記法：**

Shoulda Matchers などのワンライナーではなく、明示的記法（`expect(...).to ...`）で書く。

**ファクトリー（spec/factories/）：**

アソシエーションは `create(:model)` ではなく `association :model` で定義する（`build` 時に不要な DB 保存が走らないため）。

## 開発ワークフロー

### Git コミット規約

先頭に処理日を付け、日本語でメッセージを書く：

```
2026年4月1日・フォロー機能を追加
2026年4月1日・ログアウト後のリダイレクトバグを修正
```

- タイトルは50文字以内。本文が必要なら1行空けて「なぜ」を書く
- 1コミット = 1つの目的
- `.env`・`config/master.key`・`.idea/` などは `.gitignore` で外してある。コミットの前に `git status` で確かめる

### ブランチ戦略

- `main` は常に動作する状態を保つ
- 作業は機能ブランチで行う（例：`feature/follow-function`、`fix/logout-redirect`）
- `main` へのマージ前に `bundle exec rspec` が全件グリーンであることを確認する

### テスト方針

- モデル変更 → `spec/models/`、コントローラー変更 → `spec/requests/`、ユーザー操作 → `spec/system/` にテストを書く
- テストが書けていない機能は `# 未テスト` とコメントで明記する
- 既存のテストを壊すコミットはしない

### エラーハンドリング

- `rescue` で握りつぶさず、**根本原因を修正する**
- エラーケース（無効な入力、存在しないレコードなど）も spec でカバーする
