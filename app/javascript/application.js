import "@hotwired/turbo-rails";
import "./controllers";
import { initializeSpotifyModal } from "./controllers/spotify_modal";
import { initializeSearchConditions } from "./controllers/spotify_search";
import { initializeSpotifyAutocomplete } from "./controllers/spotify_autocomplete";
import { initializeSpotifyInput } from "./controllers/spotify_input";

/** ✅ Spotify関連機能の初期化 */
function initializeSpotifySearch() {
  console.log('🎯 Spotify関連機能の初期化開始');

  try {
    initializeSpotifyModal();
    console.log('✅ Spotifyモーダルが初期化されました');

    initializeSearchConditions();
    console.log('✅ 検索条件が初期化されました');

    initializeSpotifyAutocomplete();
    console.log('✅ オートコンプリートが初期化されました');

    initializeSpotifyInput();
    console.log('✅ 入力処理が初期化されました');
  } catch (error) {
    console.error('❌ Spotify機能の初期化中にエラーが発生しました:', error);
  }

  console.log('🎯 Spotify関連機能の初期化が完了しました');
}

/** 🎯 Turboイベントで初期化関数を再実行 */
document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);
