// 待機タブ側の Stimulus コントローラー。
//   1. AccountConfirmationChannel を waiter_sig 付きで購読
//   2. サーバから {status:"confirmed", handoff_token} を受信
//   3. 自タブから POST /auth/handoff でセッションログインを成立させる
//   4. ユーザー情報の変更画面（/profile/edit?from=confirmation）へ移る

import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
    static targets  = [ "message" ]
    static values   = { waiterSig: String }

    connect() {
        this.subscribe()
    }

    disconnect() {
        this.unsubscribe()
    }

    // AccountConfirmationChannel を購読する（サーバ側で waiter_sig を検証）
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

    unsubscribe() {
        if (!this.subscription) return
        try {
            consumer.subscriptions.remove(this.subscription)
        } catch (e) {
            console.error("サブスクリプション解除でエラー:", e)
        }
    }

    // handoff_token を /auth/handoff に POST し、自タブのセッションログインを成立させて遷移する
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

        if (!res.ok) {
            console.warn("handoff failed:", await res.text())
            return
        }

        // ログインできたら、ユーザー情報の変更画面へ移る
        // （/profile/edit は登録の直後と通常の変更の両方で使うので、?from=confirmation で見分ける）
        window.location.assign("/profile/edit?from=confirmation")
    }
}
