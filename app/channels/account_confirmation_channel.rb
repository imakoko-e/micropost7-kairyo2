# メール確認後に「待機タブ」へリアルタイム通知するためのチャンネル。
# - subscribe 時に waiter_sig（サーバ署名つきの待機情報）を検証
# - 本人の jti 単位でプライベートストリームを張る
# - subscribe より前にメール確認が走っていた場合は、保留中の handoff を即時配信する
class AccountConfirmationChannel < ApplicationCable::Channel
  # クライアントが購読開始したタイミングで呼ばれる
  def subscribed
    uid, jti = verify_waiter_sig(params[:waiter_sig])
    return reject unless uid && jti

    # jti 単位のプライベートストリームへ参加（他人の jti では受信できない）
    stream_from "confirmation_wait:#{jti}"

    # レース対策：subscribe より先に show が走っていた場合、
    # 保留中のハンドオフトークンを即時 transmit で届ける
    pending_token = WaiterRegistry.take_pending_handoff(uid)
    if pending_token.present?
      # ActionCable の transmit は引数にハッシュを1つ受け取る。
      # キーワード引数だと ArgumentError になるため、必ずハッシュとして渡す。
      transmit({
        status: "confirmed",
        message: "メールアドレスの確認が完了しました。",
        handoff_token: pending_token
      })
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    # 署名が不正なら購読拒否（改ざん・期限切れのいずれも弾く）
    reject
  end

  private

  # waiter_sig を検証し、[uid, jti] を返す。期限切れ・不正なら [nil, nil]
  def verify_waiter_sig(sig)
    return [nil, nil] if sig.blank?

    data = Rails.application.message_verifier(:waiter).verify(sig, purpose: :waiter)
    uid = data["uid"] || data[:uid]
    jti = data["jti"] || data[:jti]
    exp = (data["exp"] || data[:exp]).to_i

    # 必須値と期限をここでまとめて検証する
    return [nil, nil] if uid.blank? || jti.blank? || exp <= 0 || Time.at(exp) <= Time.current

    [uid, jti]
  end
end
