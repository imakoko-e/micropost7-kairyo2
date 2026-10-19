# micropost7-kairyo2

Railsチュートリアルのサンプルアプリ（マイクロポスト）を土台に、自分で改良を重ねた Rails アプリです。
連載「[60代からのWebシステムエンジニア](https://www.imakoko-e.jp/senior-web-engineer/)」の第7部・第8部で、作る過程を書いています。

- 土台にした教材：[Ruby on Rails チュートリアル](https://railstutorial.jp/)（第7版）Michael Hartl 著
- 作者：imakoko-e（いまここ情報システム）

## 主な機能

- ユーザー登録・ログイン（Devise）。メールアドレスの確認つき
- Google アカウントでのログイン（OmniAuth）
- **タブをまたぐ自動ログイン**：登録したタブで待っていると、メールのリンクを別のタブで開いた瞬間に、待っていたタブもログインした状態に切り替わる（Action Cable）
- 140文字のマイクロポスト（画像つき）と、相互フォロー
- ユーザー情報の入力（姓名・ふりがな・生年月日・住所。郵便番号から住所を引く）
- RSpec のテスト（134件）

サインアップからログインまでの仕組みは、[docs/signup_flow_guide.md](docs/signup_flow_guide.md)（時系列の流れ）と [docs/signup_flow_code_commentary.md](docs/signup_flow_code_commentary.md)（コードの解説）にまとめています。

## 技術スタック

Ruby 3.3.7 ／ Rails 7.2 ／ PostgreSQL 17（テストは SQLite3）／ Devise 4.9 ／ Hotwire（Turbo・Stimulus）／ Action Cable ／ Tailwind CSS ／ RSpec ／ Docker

## 節目の表

Git のタグの代わりに、改良の節目と、それを書いた連載のページをまとめます。日付は、元のリポジトリでその節目をコミットした日です。

| 日付 | 内容 | 連載 |
|---|---|---|
| 2025年4月6日 | 改良2期を始める | [7-1](https://www.imakoko-e.jp/senior-web-engineer/part07/p07-01/) |
| 2025年4月29日 | Google ログイン（OmniAuth） | [7-2](https://www.imakoko-e.jp/senior-web-engineer/part07/p07-02/) |
| 2025年5月27日 | Action Cable で、待っているタブを切り替える | [7-3](https://www.imakoko-e.jp/senior-web-engineer/part07/p07-03/)・[7-4](https://www.imakoko-e.jp/senior-web-engineer/part07/p07-04/) |
| 2025年7月10日 | Puma の前に Nginx を置き、Docker で本番へ | [7-5](https://www.imakoko-e.jp/senior-web-engineer/part07/p07-05/) |
| 2025年9月26日 | 自動ログインを設計ごと作り直す | [7-9](https://www.imakoko-e.jp/senior-web-engineer/part07/p07-09-2/) |
| 2025年10月13日 | ユーザー情報を充実させる | [7-10](https://www.imakoko-e.jp/senior-web-engineer/part07/p07-10/) |
| 2026年4月2日 | RSpec へ完全に移行する（Minitest を消す） | [8-2](https://www.imakoko-e.jp/senior-web-engineer/part08/p08-02/) |
| 2026年4月16日 | Bootstrap 5 から Tailwind CSS へ | [8-4](https://www.imakoko-e.jp/senior-web-engineer/part08/p08-04/)・[8-5](https://www.imakoko-e.jp/senior-web-engineer/part08/p08-05/) |
| 2026年5月19日 | サインアップ処理の総点検 | [8-6](https://www.imakoko-e.jp/senior-web-engineer/part08/p08-06/) |
| 2026年6月15日 | 脆弱性の対策（このリポジトリの中身の元） | [8-7](https://www.imakoko-e.jp/senior-web-engineer/part08/p08-07/)〜[8-11](https://www.imakoko-e.jp/senior-web-engineer/part08/p08-11/) |

## 動かし方（開発環境）

Docker で動かします。手元に Ruby や PostgreSQL を入れる必要はありません。

```bash
cp .env.example .env          # DB_PASSWORD には手元だけで使う値を入れる
docker compose build
docker compose run --rm app bundle install
docker compose up -d
docker compose exec app bin/rails db:prepare   # DB を作り、見本のデータを入れる
```

http://localhost:3000 で開きます。見本のデータには、管理者 `admin@rails.org` と、テスト用のユーザーが入ります（パスワードは `db/seeds.rb` を見てください）。登録のときのメールは、http://localhost:3000/letter_opener で読めます。

- `.env` の `COMPOSE_FILE=docker-compose.local.yml` により、開発用の構成が選ばれます。
- ポートは `127.0.0.1` だけで開きます。ほかのアプリとぶつかるときは、`.env` の `APP_PORT`・`DB_PORT` を変えてください。
- Google ログインを試すときだけ、`.env` に `GOOGLE_OAUTH_CLIENT_ID`・`GOOGLE_OAUTH_CLIENT_SECRET` を入れます。

テストは app のコンテナの中で動かします。

```bash
docker compose exec app bundle exec rspec
```

`bin/dev`（`docker compose up`）で起動していないときは、先に `docker compose exec app bin/rails tailwindcss:build` を実行してください（CSS の生成物は Git に入っていません）。

## 本番用のファイルについて

`Dockerfile`・`Dockerfile.db`・`docker-compose.yml`・`nginx/`・`postgresql/` は、さくらの VPS で動かしていた本番構成（Nginx ＋ Puma ＋ PostgreSQL ＋ Redis）の記録です。ホスト名・パスワードなどの値は取り除き、環境変数（見本は `.env.production.example`）から読む形にしてあります。

## 注意

- **当時の版のままです。** Rails 7.2 は保守が終わっています。学習用の記録として公開しているもので、そのまま本番に使うことは想定していません。
- **履歴は公開していません。** 元のリポジトリには秘密の値やコメントにした古いコードが残っていたため、2026年6月15日の時点のコードから秘密の値を取り除き、コメントを整理してから、1つのコミットにまとめました。整理の途中で見つけた不具合（メールアドレス・パスワードの変更の後のエラーなど）と、使っていないファイルも、このときに直しています。改良の過程は連載に書いています。

## ライセンス

[MIT License](LICENSE) です。土台の Railsチュートリアルのサンプルアプリのコードは、MIT License と Beerware License のもとで公開されています（Copyright (c) 2022 Michael Hartl）。
