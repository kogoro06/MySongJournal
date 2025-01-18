// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Stimulus設定
const application = Application.start()

// コントローラーを登録
import SpotifySearchController from "./controllers/spotify_search_controller"
application.register("spotify-search", SpotifySearchController)

// その他のSpotify関連機能をインポート
import { initializeSpotifyModal } from "./controllers/spotify_modal"
import { initializeSpotifyAutocomplete } from "./controllers/spotify_autocomplete"
import { initializeSpotifyInput } from "./controllers/spotify_input"

/** ✅ Spotify関連機能の初期化 */
function initializeSpotifySearch() {
  console.log('🎯 Spotify関連機能の初期化開始');

  try {
    initializeSpotifyModal();
    console.log('✅ Spotifyモーダルが初期化されました');

    initializeSpotifyAutocomplete();
    console.log('✅ オートコンプリートが初期化されました');

    initializeSpotifyInput();
    console.log('✅ 入力フィールドが初期化されました');
  } catch (error) {
    console.error('❌ 初期化中にエラーが発生しました:', error);
  }
}

/** 🎯 Turboイベントで初期化関数を再実行 */
document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);
