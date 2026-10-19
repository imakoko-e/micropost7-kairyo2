# 本番用の Dockerfile。マルチステージビルドでイメージサイズを小さくする（開発用は Dockerfile.local）
# ビルド方法（本番用。compose の image: rails-app:latest と同じ名前にする）
#       $ docker build --build-arg RAILS_ENV=production --secret id=rails_master_key,src=config/master.key -t rails-app:latest .

##############################
# --- 1st stage build ---
# ビルドステージ: 必要な依存関係のインストールとアセットのプリコンパイル
##############################
#■■ ベースとなるrubyイメージを指定（Ruby 3.3.7を利用）
FROM ruby:3.3.7 AS builder

#■■ ビルド時の環境変数

# 既定は development。本番用はビルド時に --build-arg RAILS_ENV=production で上書きする
ARG RAILS_ENV=development

# ENV はコンテナ実行時の環境変数を指定
ENV RAILS_ENV=${RAILS_ENV}

#■■ タイムゾーン情報を環境変数でも明示
ENV TZ=Asia/Tokyo

#run(ラン)はdocker-compose build 又は、docker build コマンドで実行される
# \ バックスラッシュでコードを改行して見易くする (\ はoption+¥です)
#■■ OSパッケージのインストール
#【ビルド依存関係で必要なパッケージのインストール】
# update で最新のパッケージ一覧を取り（-qq はエラー以外を表示しない）、-y で確認なしに入れる
# rm -rf /var/lib/apt/lists/* … apt のキャッシュを消して、イメージを小さくする
# ・build-essential → ネイティブ拡張を持つGem（例：nokogiriなど）のコンパイルに必要。
# ・nodejs は JavaScript 関連（例：アセットプリコンパイル）に必要
# ・postgresql-client は DB 接続用に必要
# ・ruby-dev → Ruby のヘッダー（ネイティブ拡張のビルド用）
# ・libxml2-dev,libxslt1-dev,zlib1g-dev　････ nokogiri用 -devパッケージが必要（アセットコンパイルに必要）
# ・tzdata　　tzdata パッケージを入れることで /usr/share/zoneinfo/Asia/Tokyo が使えるようになる
# ・ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime → システム全体のタイムゾーンを JST（日本時間）に切り替える。
RUN apt-get update -qq && \
    apt-get install -y \
      build-essential nodejs postgresql-client ruby-dev tzdata \
      libxml2-dev libxslt1-dev zlib1g-dev && \
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

#■■ アプリケーションの作業ディレクトリを指定
WORKDIR /app

# 【依存関係インストール】
#■■ GemfileとGemfile.lockをコンテナにコピーして、bundle install時のキャッシュを有効化する
COPY Gemfile Gemfile.lock /app/

#■■ 必要なgemをインストール
# オプションの意味:
#   --jobs=4      : 4 並列でインストールを行う（高速化）
#   --retry=3     : インストール失敗時に最大 3 回リトライする
#   --without development test : 開発(test)用のGemグループを除外してインストール
# ※ 開発環境の場合は、通常 development や test 用のGemも必要 →　"--without development test" の部分を省略する。
RUN bundle config set --local path '/usr/local/bundle'      # gem のインストール先を /usr/local/bundle に明示的に設定

RUN if [ "$RAILS_ENV" = "production" ]; then \
      echo "●●【本番環境用　bundle install --without development test】" >&2 && \
      bundle install --jobs=4 --retry=3 --without development test; \
    else \
      echo "●●【開発環境用　bundle install --without production】" >&2 && \
      bundle install --jobs=4 --retry=3 --without production; \
    fi

#■■ アプリケーションコード全体をコンテナにコピー
COPY . /app

#■■　本番用アセットプリコンパイルの実行
# assets:precompile（アセットファイルの事前コンパイル）
# 理由: 本番環境では、アセット（JavaScript、CSS等）の事前コンパイルにより、アプリ起動時の負荷を軽減し、パフォーマンスを向上させる
# Production のアセットプリコンパイル（BuildKit の secret から master.key を読み込み）
# 注意: SECRET_KEY_BASE は precompile にダミーで十分。重要なのは RAILS_MASTER_KEY を渡すこと。
RUN --mount=type=secret,id=rails_master_key \
    if [ "$RAILS_ENV" = "production" ]; then \
      echo "●●● Precompiling assets for production（本番環境用にアセットファイルの事前コンパイル）..." >&2 && \
      export RAILS_MASTER_KEY="$(cat /run/secrets/rails_master_key)" && \
      SECRET_KEY_BASE=dummy DATABASE_URL=postgresql://dummy:dummy@localhost:5432/dummy REDIS_URL=redis://localhost:6379/0 bundle exec rails assets:precompile RAILS_ENV=production && \
      rm -rf node_modules tmp/cache log/*; \
    else \
      echo "●●● Skipping asset precompilation in development mode（開発環境モードで、アセットのプリコンパイルをスキップする）" >&2; \
    fi


##############################
# --- 2st stage build ---
# ランタイムステージ（最終的なイメージのビルドステージ）: 軽量な本番用イメージの作成
##############################
FROM ruby:3.3.7-slim

#■■ ビルド時の環境変数
# 既定は development。本番用はビルド時に --build-arg RAILS_ENV=production で上書きする
ARG RAILS_ENV=development

# ENV はコンテナ実行時の環境変数を指定
ENV RAILS_ENV=${RAILS_ENV}

#■■ OSパッケージのインストール
# 実行に要るパッケージだけ（1st stage から build-essential などビルド用を外す）
RUN apt-get update -qq &&  \
    apt-get install -y nodejs postgresql-client && \
    # imagemagick は画像の縮小（Active Storage の variant）に要る \
    apt-get install -y imagemagick && \
    rm -rf /var/lib/apt/lists/*

#■■ アプリケーションの作業ディレクトリを指定
WORKDIR /app
#■■ 1st ビルドステージで作成したアプリケーションファイルをコピー（必要な実行ファイルをコピー）
COPY --from=builder /app /app

#■■ ビルドステージのGemインストール結果をコピー
# ビルドステージとランタイムステージのベースイメージが同じ場合に有効。ランタイムイメージをより軽量にできる。
# builder ステージから gem インストール済みのディレクトリをコピー
COPY --from=builder /usr/local/bundle /usr/local/bundle

#■■ 実行権限の付与 （権限エラー対策）
# /app/bin/railsに実行権限が無いと、実行時に「Permission denied」となる
RUN chmod +x /app/bin/rails

#■■ Puma 用のディレクトリを確実に作成
RUN mkdir -p tmp/sockets tmp/pids

#■■ エントリーポイント設定
# エントリーポイントスクリプト（entrypoint.sh）を利用して、起動前にDB接続待機などの初期化処理を実装できます。
# DBがまだ起動していない場合の接続エラー防止に役立ちます。
# ※ entrypoint.sh ファイル内で、DB接続待機などの初期化処理を実装する（済み）。
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

#■■ 非rootユーザーで実行する設定
# 理由: セキュリティ向上のため、コンテナ内のプロセスは権限を限定したユーザーで実行するのが望ましい。
#  appuser は、Rails アプリケーションを実行する app コンテナ 用の非rootユーザー。
#  db:コンテナのPostgreSQLは独自ユーザー（通常は postgres）で動作するため、appuser は db コンテナには関係ない。）
# chown ディレクトリ（ファイル）の所有権を変更する　　-R:ディレクトリ内の所有権も変更する
# appuser を ssl-cert グループ（SSL 証明書を読めるグループ）に入れる。
# 本番は、ホストの ssl-cert グループと同じ GID（1001。ホストで getent group ssl-cert で調べた）にする
RUN \
    # ── 既に group があれば何もしない ──
    if getent group ssl-cert >/dev/null 2>&1; then \
        echo "●● group ssl-cert は、既に存在してます･････"; \
    else \
        if [ "$RAILS_ENV" = "production" ]; then \
            echo "●● ssl-cert グループを GID 1001 （本番環境）で作成･････"; \
            groupadd -g 1001 ssl-cert; \
        else \
            echo "●● ssl-cert グループを GID 118 （開発環境）で作成･････"; \
            groupadd -g 118 ssl-cert; \
        fi \
    fi \
    && useradd -m appuser && usermod -a -G ssl-cert appuser && chown -R appuser /app

# Gemのディレクトリの所有者を変更（appuserがアクセスできるように）
RUN chown -R appuser:appuser /usr/local/bundle

#■■ 非rootユーザーで実行するため、USER命令でユーザーを変更
USER appuser

#■■ コンテナが公開するポート（Pumaがリッスンするポート）を指定
# EXPOSE はしない。本番の Puma は UNIX ソケットで待ち受ける。UNIX ソケットはファイルシステム（tmp/sockets/puma.sock）を介して通信するので、TCP ポート 3000 はまったく使いません。

#■■ 初期化処理として、server.pidの削除（ビルド時に存在する場合のみ）
RUN rm -f tmp/pids/server.pid

#■■ コンテナ起動時のデフォルトコマンド定義
# Webサーバー(Puma)を起動する（以降、永続的なプロセス）
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
