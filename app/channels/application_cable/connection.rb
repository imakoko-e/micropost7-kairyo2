# WebSocket 接続ごとのベースクラス。
# 認証の本体は AccountConfirmationChannel 側で waiter_sig を検証して行うため、
# ここでは Warden からログイン中ユーザーを拾えれば拾う、という最小構成にしてある。
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # 接続ごとにログイン中ユーザー（いれば）を識別子として保持する
    identified_by :current_user

    # 未ログイン接続も拒否せず受け入れる
    # 理由：メール確認「待機中」のタブはログイン前に WebSocket を張る必要があるため
    def connect
      self.current_user = env['warden']&.user(:user)
    end
  end
end
