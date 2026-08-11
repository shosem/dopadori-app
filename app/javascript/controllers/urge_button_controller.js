import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="urge-button"
export default class extends Controller {
  static targets = [ "form", "cycle", "label" ]
  connect() {
    console.log("つながってるよ！")
  }
}
