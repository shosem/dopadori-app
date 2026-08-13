import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="urge-button"
export default class extends Controller {
  static targets = ["form", "circle", "label"]
  connect() {
    console.log("つながってるよ！")
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

    this.labelTarget.textContent = { inhale: "3秒で息を吸って...", hold: "3秒息を止めて", exhale: "6秒でゆっくり吐きましょう" }[phase]
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
