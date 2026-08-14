import { Controller } from "@hotwired/stimulus"

// チェックした瞬間にフォームを送る。
// onchange をERBにインラインで書くと CSP に弾かれるため、ここに寄せている。
// form 要素そのものに data-controller="auto-submit" を付けて使う。
export default class extends Controller {
  submit() {
    // submit() ではなく requestSubmit()。submit() は Turbo のイベントを飛ばさないので、
    // ページ全体がリロードされて Turbo Drive を素通りする。
    this.element.requestSubmit()
  }
}
