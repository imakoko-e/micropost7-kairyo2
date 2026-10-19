#!/bin/bash
#!/bin/sh  #shellのnc（netcat）コマンドがインストールされてないため、bashに変更する
# スクリプトの最初にシェルを指定 (#!/bin/sh)することで、どのシェルで実行するか明示しています。

# entrypoint.sh
# Dockerfile から エントリーポイントスクリプト（entrypoint.sh）を起動

# 「set -e」を設定することで、途中でエラーが発生した場合にスクリプトの実行を終了する。
set -e

# --- DB接続待機処理 ---
# DATABASE_HOST と DATABASE_PORT（PostgreSQLのデフォルトポートは5432）を使って、DBサーバーが起動して接続可能になるまで待機します。
# ここでは「nc (netcat)」を使って接続チェックを行っています。
# ※ netcatがインストールされていない場合は、Dockerfileでインストールするか、別の方法（例：bashのuntilループ＋/dev/tcp）を検討してください。
#echo "Waiting for database to be available..."

echo "データベースが利用可能になるまで待機しています...【Dockerfile --> entrypoint.sh】"

#while ! nc -z ${DATABASE_HOST:-db} ${DATABASE_PORT:-5432}; do
#  sleep 1           # 接続できるまで1秒ごとにループし待機します。
#  #echo "Still waiting for database..."
#  echo "まだデータベースを待っています...【Dockerfile --> entrypoint.sh】"
#done

# デフォルトは DATABASE_HOST=db, DATABASE_PORT=5432 を使用
DB_HOST=${DATABASE_HOST:-db}
DB_PORT=${DATABASE_PORT:-5432}

# Bash 固有の /dev/tcp 機能 を使って接続確認　（スクリプト内容は未確認）
while ! (echo > /dev/tcp/${DB_HOST}/${DB_PORT}) 2>/dev/null; do
  echo "まだデータベースを待っています...【Dockerfile --> entrypoint.sh】"
  sleep 1
done

#echo "Database is up!"
echo "データベースが起動しました!  【Dockerfile --> entrypoint.sh】"

# --- 共有ディレクトリの権限調整 ---
echo "共有ディレクトリのパーミッションを調整します...【Dockerfile --> entrypoint.sh】"
# Nginxコンテナ(nginxユーザー)がプロジェクトルートを辿れるように実行権限を付与
chmod o+x /app
# Nginxコンテナ(nginxユーザー)がアクセスできるように、
# public(静的ファイル)とtmp(ソケット)ディレクトリのパーミッションを調整する
chmod -R 777 tmp
chmod -R a+rX public

# --- gemのインストール確認と自動実行 ---
echo "必要なgemを確認しています..."
# bundle check は、必要なgemがインストール済みかどうかを確認、インストールされていなければ bundle install を実行し、足りないgemを自動でインストール
#bundle check || bundle install
bundle check

# --- 必要に応じた初期化処理 ---
# 例えば、DBマイグレーションを自動実行する場合は以下を有効にできます。
# echo "Running database migrations..."
# bundle exec rails db:migrate

# --- CMDで指定されたコマンドの実行 ---
# このスクリプトをENTRYPOINTとして指定している場合、CMDで指定されたコマンドが「$@」として渡されます。
# 「exec」を使うことで、シェルプロセスを置き換え、コンテナ内で正しくPID1として実行されるようにします。
exec "$@"
