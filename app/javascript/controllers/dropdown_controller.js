// アカウントのドロップダウンメニューを開閉する
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  // ドロップダウンの表示/非表示を切り替える
  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  // ドロップダウン外クリックで閉じる
  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
}
