# Webサーバー puma の設定ファイル
# 環境変数 "RAILS_ENV" で開発と本番を切り替える。本番は Nginx の後ろで UNIX ソケットを使い、HTTPS は Nginx が受け持つ

#■■ Puma が実行される 環境変数を指定する。
# 環境変数 "RAILS_ENV" を利用して、実行環境（例: development, production）を設定します。
# 環境変数が設定されていない場合は "development" をデフォルトにします。
environment ENV.fetch("RAILS_ENV") { "development" }

#■■ Pumaが利用するスレッド数（最低／最大）を設定する。
# Pumaは内部スレッドプールから各リクエストをスレッドで処理できます。
# Threads` メソッドの設定は、最小値と最大値の2つの数値を取ります。
# スレッドプールを使用するライブラリは、Pumaに指定された最大値に合わせて設定する必要があります。これはActive Recordのデフォルトのスレッドサイズと同じです。
# RAILS_MAX_THREADS 環境変数（デフォルトは5）で、最小と最大のスレッド数を指定します。
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

#■■ ワーカータイムアウト設定
# Puma が開発環境でワーカーを終了させる前に待つ `worker_timeout` しきい値を指定します。
# ワーカーが一定時間（ここでは 60 秒）応答しない場合に、Puma はそのワーカーを自動的に再起動します。
# 開発では、長い処理の途中で誤って再起動されないよう、3600 秒にのばす
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

#■■ Puma が使用する pid ファイルの設定（プロセス管理用。任意）
# pidfile は Puma プロセスの ID を記録するファイルです。
# サーバー管理（プロセスの停止や再起動）のために利用されます。
# 環境変数 PIDFILE が設定されていればその値を、なければデフォルトで "tmp/pids/server.pid" を利用します。
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

#■■ pumactl などが使う状態ファイル
state_path "tmp/pids/puma.state"


#■■ 待ち受け先（本番は UNIX ソケット、開発は TCP の 3000番）
if ENV.fetch("RAILS_ENV") { "development" } == "production"
  # 本番環境：Nginx 経由（Unix ソケット）
  bind "unix://#{File.expand_path('../tmp/sockets/puma.sock', __dir__)}?umask=0000"
else
  # 開発環境：ブラウザから http://localhost:3000 で直接アクセスできるよう TCP
  port ENV.fetch("PORT") { 3000 }
end


#■■ Pumaのワーカー（Ruby プロセス数）の数を設定する。（マルチプロセス運用）
# クラスタモードで起動する `workers` の数を指定します。
# ワーカーはフォークされたWebサーバプロセスです。スレッドとワーカーを併用する場合、アプリケーションの同時実行数は最大 `threads` * `workers` となる。
# ワーカーはJRubyやWindowsでは動作しません(どちらもプロセスをサポートしていません)。
# WEB_CONCURRENCY 環境変数で指定（既定は 1）。開発ではクラスタモードにしない
if ENV.fetch("RAILS_ENV") { "development" } == "production"
  workers ENV.fetch("WEB_CONCURRENCY") { 1 }       # 本番のみクラスタモード
end


#■■ アプリケーションのプリロード（パフォーマンス最適化）
# workers` 番号を指定する場合は `preload_app!` メソッドを使用してください。
# このディレクティブは Puma に、アプリケーションをフォークする前にまずアプリケーションを起動してコードをロードするように指示します。
# これは Copy On Write プロセスの動作を利用するため、ワーカーが使用するメモリは少なくなります。
# preload_app! を指定することで、ワーカーの起動時にアプリケーションを先に読み込み、効率的なフォークが行えます。
# これにより、Warden/Deviseの初期化問題を防ぎます。
preload_app!


#■■ ワーカーの起動時のフック
# preload_app! を使う場合、ワーカー起動時にDB接続を再確立する必要があります。
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end


#■■ Warden（Devise）のウォームアップ
# Devise の最初の自動サインインが失敗することがあったため、
# ワーカー起動直後にアプリにダミーのリクエストを送り、Warden を初期化するコードを有効化
on_worker_boot do
  sock_path = File.expand_path('../tmp/sockets/puma.sock', __dir__)
  # ワーカーがブートしたあとに1秒待ってHTTPリクエスト
  Thread.new do
    sleep 1  # 少し待ってから
    system("curl -fsS --unix-socket #{sock_path} http://localhost/ -o /dev/null")  # curl の出力を /dev/null に捨てる
    puts "✅ Warden(Devise)ウォームアップ・リクエスト送信（puma ソケット経由）"
  end
end



#■■ プラグイン設定
# クラッシュ時の自動再起動（開発向け）
# Pumaの再起動を容易にするため、tmp_restartプラグインを有効にします。
# bin/rails restart` コマンドによる puma の再起動を許可する。
plugin :tmp_restart



