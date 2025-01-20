import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  // パスワードの表示/非表示を切り替える
  toggle() {
    if (this.inputTarget.type === "password") {
      this.inputTarget.type = "text"
      this.buttonTarget.textContent = "🙈" // Hide icon
    } else {
      this.inputTarget.type = "password"
      this.buttonTarget.textContent = "👁" // Show icon
    }
  }
}