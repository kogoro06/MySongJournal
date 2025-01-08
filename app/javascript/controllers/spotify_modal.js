// ✅ モーダルを開く関数
function openSpotifyModal() {
  const spotifyModal = document.getElementById('spotify-modal');
  const modalContent = document.getElementById('spotify-modal-content');

  if (!spotifyModal || !modalContent) {
    console.error('⚠️ モーダル要素が見つかりません。');
    return;
  }

  spotifyModal.showModal();

  fetch('/spotify/search', {
    headers: { 'X-Requested-With': 'XMLHttpRequest' }
  })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTPエラー! ステータス: ${response.status}`);
      }
      return response.text();
    })
    .then(html => {
      modalContent.innerHTML = html;

      // 検索条件初期化
      import('./spotify_search.js')
        .then(module => module.initializeSearchConditions())
        .catch(error => console.error('検索条件モジュールの読み込みに失敗:', error));

      // 年代トグル初期化
      import('./spotify_year_toggle.js')
        .then(module => module.initializeYearToggle())
        .catch(error => console.error('年代トグルモジュールの読み込みに失敗:', error));

      // オートコンプリート初期化
      import('./spotify_autocomplete.js')
        .then(module => module.initializeSpotifyAutocomplete())
        .catch(error => console.error('オートコンプリートモジュールの読み込みに失敗:', error));
    })
    .catch(error => {
      modalContent.innerHTML = '<p class="text-red-500">検索フォームの読み込みに失敗しました。</p>';
      console.error('モーダルコンテンツの読み込みエラー:', error);
    });
}

// ✅ 初期化関数
function initializeModal() {
  const openModalButton = document.getElementById('open-search-modal');
  const reopenModalButton = document.getElementById('reopen-search-modal');
  const spotifyModal = document.getElementById('spotify-modal');
  const modalContent = document.getElementById('spotify-modal-content');

  if (openModalButton) openModalButton.addEventListener('click', openSpotifyModal);
  if (reopenModalButton) reopenModalButton.addEventListener('click', openSpotifyModal);

  if (spotifyModal) {
    spotifyModal.addEventListener('close', () => {
      modalContent.innerHTML = '';
    });
  }
}

// ✅ TurboとDOMContentLoadedで初期化
document.addEventListener('turbo:load', initializeModal);
document.addEventListener('DOMContentLoaded', initializeModal);
