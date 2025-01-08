// Entry point for the build script in your package.json
import "@hotwired/turbo-rails";
import "./controllers";
import "./controllers/spotify_modal";
import { initializeSearchConditions } from "./controllers/spotify_search";
import { initializeYearToggle } from "./controllers/spotify_year_toggle";
import "./controllers/spotify_autocomplete";

function initializeSpotifySearch() {
  initializeSearchConditions();
  initializeYearToggle();
}

document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);
