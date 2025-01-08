import "@hotwired/turbo-rails";
import "./controllers";
import { initializeSpotifyModal } from "./controllers/spotify_modal";
import { initializeSearchConditions } from "./controllers/spotify_search";
import { initializeYearToggle } from "./controllers/spotify_year_toggle";
import { initializeSpotifyAutocomplete } from "./controllers/spotify_autocomplete";
import { initializeSpotifyInput } from "./controllers/spotify_input";

/** ✅ Spotify関連機能の初期化 */
function initializeSpotifySearch() {
  initializeSearchConditions();
  initializeYearToggle();
  initializeSpotifyModal();
  initializeSpotifyAutocomplete();
  initializeSpotifyInput();
}

document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);
