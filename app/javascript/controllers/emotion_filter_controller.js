import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  filter(event) {
    // フォームを取得して送信
    event.currentTarget.form.requestSubmit()
  }
}
