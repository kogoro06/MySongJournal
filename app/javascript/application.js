// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import './controllers/modal';
import "./controllers/search";
import "./controllers/search_conditions";

document.addEventListener('turbo:load', initializeButtonsAndModal);
document.addEventListener('turbo:render', initializeButtonsAndModal);
document.addEventListener('DOMContentLoaded', initializeButtonsAndModal);
