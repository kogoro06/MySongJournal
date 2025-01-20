// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import "./controllers"
import { togglePasswordVisibility } from "./controllers/password_visibility_controller"

const application = Application.start()
window.Stimulus = application
window.togglePasswordVisibility = togglePasswordVisibility;