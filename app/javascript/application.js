// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "./controllers";
import "./controllers/modal";
import { initializeSearchConditions } from "./controllers/spotify_search";
import { initializeYearToggle } from "./controllers/spotify_year_toggle";

function initializeSpotifySearch() {
  initializeSearchConditions();
  initializeYearToggle();
}

document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);
