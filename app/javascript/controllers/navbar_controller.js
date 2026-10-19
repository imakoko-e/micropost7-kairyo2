// モバイルのハンバーガーメニューを開閉する
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  // ハンバーガーボタンクリックでメニューを開閉する
  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }
}
