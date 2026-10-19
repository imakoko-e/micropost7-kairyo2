# リポジトリガイドライン

## プロジェクト概要

Ruby 3.3.7 / Rails 7.2 のマイクロポストアプリです。ユーザー登録、メール確認、ログイン、Google OAuth2、140文字以内のマイクロポスト投稿、画像添付、相互フォロー、ActionCable によるリアルタイム更新（メール確認を待っているタブを、確認の完了と同時にログインさせる）を扱います。認証は Devise 4.9、フロントエンドは Hotwire（Turbo / Stimulus）と importmap と Tailwind CSS、テストは RSpec を使います。

## ディレクトリ構成

アプリ本体は `app/` 配下にあります。モデルは `app/models/`、コントローラーは `app/controllers/`、ビューは `app/views/`、ActionCable のチャンネルは `app/channels/`、サービスは `app/services/`、Stimulus / JavaScript は `app/javascript/`、スタイルと Tailwind の入口は `app/assets/` に置きます。メールは Devise のメーラーが送るので、`app/mailers/` はありません。

設定は `config/`、DB 関連は `db/`、ロケールは `config/locales/` です。RSpec は `spec/models/`、`spec/requests/`、`spec/system/`、`spec/channels/`、`spec/services/`、`spec/factories/` に分けます。開発用の Docker 構成は `Dockerfile.local`・`docker-compose.local.yml`、本番用は `Dockerfile`・`Dockerfile.db`・`docker-compose.yml`・`nginx/`・`postgresql/` です。サインアップの流れの解説は `docs/` にあります。

## 主要な構成

- `User`: Devise 認証。`database_authenticatable`、`registerable`、`confirmable`、`trackable`、`omniauthable` を使います。`first_name`、`last_name`、`kana`、`birthday`、`address` などの独自フィールドを持ちます。
- `Micropost`: `User` に属します。本文は最大140文字、画像は ActiveStorage の `has_one_attached :image`、標準の並び順は `created_at DESC` です。
- `Relationship`: `follower_id` / `followed_id` で `users` をつなぎ、フォロー中・フォロワーを表現します。
- Devise のカスタムコントローラーは `app/controllers/users/` 配下に置きます。確認待ち画面は `/users/confirm_wait?sig=...` で、id は URL に載せず署名付きトークンで渡します。
- `AuthHandoffsController` はメール確認中のブラウザタブ間ログイン状態の引き継ぎに使います（`POST /auth/handoff`）。
- セッションは、本番は Redis（`REDIS_URL` が必須）、開発は Cookie です。関連設定は `config/initializers/session_store.rb` と `config/initializers/redis.rb` です。
- 開発環境・本番は PostgreSQL 17、テスト環境は SQLite3 です。
- 開発環境のメール確認は LetterOpenerWeb を `/letter_opener` で使います。

## 開発・ビルド・テストコマンド

開発は Docker で行います。`.env.example` を `.env` に写すと、`COMPOSE_FILE=docker-compose.local.yml` により `docker compose` が開発用の構成を使います。

- `cp .env.example .env`: 開発用の環境変数を用意します（`DB_PASSWORD` は手元用の値を入れます）。
- `docker compose build` / `docker compose run --rm app bundle install`: イメージを作り、gem を入れます。
- `docker compose up -d`: app（`bin/dev`：Rails サーバーと Tailwind watcher）と db を起動します。`http://localhost:3000` で開きます。
- `docker compose exec app bin/rails db:prepare`: 開発用 DB を作成・マイグレーションし、seed を入れます。
- `docker compose exec app bundle exec rspec`: RSpec を全件実行します。
- `docker compose exec app bundle exec rspec spec/models/user_spec.rb`: 特定ファイルだけ実行します。
- `docker compose exec app bundle exec rspec spec/models/user_spec.rb:42`: 指定行の spec を実行します。
- `docker compose exec app bin/rails tailwindcss:build`: `bin/dev` を起動していないときに、RSpec の前に実行します（`app/assets/builds/tailwind.css` は Git に入っていません）。
- `docker compose -f docker-compose.yml build && docker compose -f docker-compose.yml up -d`: 本番のスタックをビルド・起動します（環境変数は `.env.production`）。

## コーディング規約

インデントは半角スペース2つに統一します。Rails 標準の命名規則に従い、ファイル名・メソッド名は `snake_case`、クラス・モジュールは `CamelCase`、コントローラー名は複数形、モデル名は単数形にします。

モデルは `include`、定数、アソシエーション、バリデーション、コールバック、スコープ、公開メソッド、`private` の順に整理します。コントローラーは `before_action`、アクション、`private` の順に整理し、`private` 以下ではストロングパラメータ、認可・補助メソッドの順を基本にします。`before_action` は原則 `only:` で対象アクションを限定します。

不要になったコード、デバッグログ、コメントアウトした死んだコードは残しません（消したコードは Git の履歴に残ります）。秘密の値はコードに書かず環境変数から読み、`.env.example` には名前だけを書きます。

## コメント規約

コメントは日本語で書きます。処理内容が自明な行に説明を足すのではなく、意図・背景・注意点が読み取りにくい箇所に絞ります。日付や演習番号だけのメモは書きません。

- クラスや主要メソッドの冒頭には「何をするか」を1行で書きます。
- Rails 特有の `before_action`、`validates`、callback などは、初心者に意図が伝わりにくい場合に補足します。
- 条件分岐は、なぜその条件が必要かが自明でない場合に理由を書きます。
- model では業務ルール、validation の背景、callback の副作用を補足します。
- controller では認可、分岐理由、外部仕様との対応を補足します。
- service object では入力、出力、副作用、失敗時の扱いを補足します。
- initializer / config では設定理由と、変更時に影響する箇所を補足します。

## ビュー・フロントエンド

ERB コメントは `<%# コメント %>` を使い、`<%#= %>` は使いません。複雑な条件分岐や Turbo / Stimulus / ActionCable と連動する箇所は、日本語コメントで意図を補足します。Tailwind CSS の既存スタイルやコンポーネントの見た目を優先し、UI 変更は既存のトーンに合わせます。

## テスト方針

RSpec を使います。モデルの validation / association は model spec、コントローラーやルーティングを含む挙動は request spec、ブラウザ操作は system spec（`driven_by(:rack_test)`）、共通データは factory で扱います。`spec/support/` 配下は `rails_helper.rb` で自動ロードされ、FactoryBot の `build`、`create` などは spec 内で直接使えます。

`describe`、`context`、`it` のラベルは日本語で書きます。`describe` は対象機能、`context` は条件、`it` は期待結果を表します。DB 保存が不要なら `build` を使い、永続化が必要な場合だけ `create` を使います。Factory の association は `create(:model)` ではなく `association :model` で定義します。

Shoulda Matchers などのワンライナーではなく、明示的記法（`expect(...).to ...`）で書きます。未テストの機能を残す場合は `# 未テスト` と理由を明記します。

## Git・PR

コミットメッセージは日本語で、先頭に処理日を付けます。

```text
2026年4月21日・サインアップ処理フローを修正
2026年4月21日・ログアウト後のリダイレクトバグを修正
```

1コミットは1目的に絞ります。タイトルはできるだけ50文字以内にし、本文が必要な場合は1行空けて「なぜ」を書きます。`main` は常に動作する状態を保ち、作業は `feature/follow-function` や `fix/logout-redirect` のような目的別ブランチで行います。PR 前には `bundle exec rspec` を実行し、変更内容・理由・関連 issue・UI 変更時のスクリーンショットを添えます。

## セキュリティ・運用上の注意

秘密情報、credentials、DB ダンプ、実行時生成データはコミットしません。`.env`・`.env.*`（`.env.example`・`.env.production.example` を除く）、`config/master.key`、`.idea/`・`.vscode/`、`tmp/`、`log/`、`storage/`、`postgres_data/`、`storage_data/` は `.gitignore` で外してあります。例外処理では `rescue` で握りつぶさず、根本原因を修正します。無効な入力、存在しないレコード、権限不足などのエラーケースも可能な範囲で spec に含めます。
