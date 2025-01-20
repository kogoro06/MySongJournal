// ⚡️ アプリケーションのエントリーポイント
import "@hotwired/turbo-rails"
import "./controllers"  // Stimulusコントローラーをインポート

// 🎵 Spotify関連機能のインポート
import { initializeSpotifyModal } from "./controllers/spotify_modal"
import { initializeSpotifyAutocomplete } from "./controllers/spotify_autocomplete"
import { initializeSpotifyInput } from "./controllers/spotify_input"

/** 
 * ✨ Spotify関連機能の初期化
 * モーダル、オートコンプリート、入力フィールドの設定を行う
 */
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

/** 
 * 🔄 ページ遷移時の再初期化設定
 * Turboとの連携のため、各イベントで初期化関数を実行
 */
document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);
