// 郵便番号から住所を調べて（ZipCloud の API）、都道府県・市区町村・町名の欄に入れる

import { Controller } from "@hotwired/stimulus"

// data-controller="address-lookup" の要素に接続する

export default class extends Controller {
    static targets = ["postal", "pref", "city", "streetName"]

    // 「住所検索」ボタンのクリックに反応
    async search() {
        const raw = (this.postalTarget.value || "").replace(/[^\d]/g, "")
        if (raw.length !== 7) {
            alert("郵便番号は7桁で入力してください（例: 1000001）")
            return
        }
        try {
            // ZipCloud API の仕様: https://zipcloud.ibsnet.co.jp/
            const res = await fetch(`https://zipcloud.ibsnet.co.jp/api/search?zipcode=${raw}`)
            const json = await res.json()
            if (json.status !== 200 || !json.results || json.results.length === 0) {
                alert("住所が見つかりませんでした。郵便番号を確認してください。")
                return
            }

            // 最初の候補を採用
            const a = json.results[0]
            const prefecture = a.address1 || ""         // 都道府県
            const city = a.address2 || ""               // 市区町村
            const street_name = a.address3 || ""        // 町域（⇒ 町名へ補完）

            // 取得した値をフォームに反映
            if (this.hasPrefTarget) this.prefTarget.value = prefecture
            if (this.hasCityTarget) this.cityTarget.value = city
            if (this.hasStreetNameTarget) this.streetNameTarget.value = street_name
        } catch (e) {
            console.error(e)
            alert("住所検索でエラーが発生しました。時間をおいて再度お試しください。")
        }
    }
}

