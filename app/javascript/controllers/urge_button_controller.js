import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="urge-button"
export default class extends Controller {
  static targets = ["form", "circle", "label"]

  // 連打1回ぶんの手応え。押した回数はどこにも持たない(数えた時点で表示できてしまう)。
  press() {
    this.start()

    // 一度クラスを外し、レイアウトを強制的に読ませてから付け直す。この1行がないと
    // 再生中のアニメーションが頭に戻らず、2回目以降の連打に手応えが返らない。
    this.circleTarget.classList.remove("is-pressed")
    void this.circleTarget.offsetWidth
    this.circleTarget.classList.add("is-pressed")
  }

  start() {
    if (this.startedAt) return
    this.startedAt = Date.now()
    this.timer = setInterval(() => this.tick(), 100)
  }

  tick() {
    const elapsed = Date.now() - this.startedAt
    if (elapsed >= 36000) return this.finish()

    // 経過時間を12で割って、3-3-6呼吸のセクションを区別
    const inCycle = elapsed % 12000
    const phase = inCycle < 3000 ? "inhale" : inCycle < 6000 ? "hold" : "exhale"
    if (phase === this.phase) return
    this.phase = phase

    this.labelTarget.textContent = {
      inhale: "3秒で息を吸って...",
      hold: "3秒息を止めて",
      // \n で折り返す位置を固定する。textContent なので <br> は文字として出てしまう。
      // 受け側の whitespace-pre-line とセットで効く(ビュー側のクラスを外すと1行に戻る)。
      exhale: "連打を休んで、\n6秒でゆっくり吐きましょう"
    }[phase]
    this.circleTarget.dataset.phase = phase
  }

  finish() {
    clearInterval(this.timer)
    this.formTarget.requestSubmit()
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
