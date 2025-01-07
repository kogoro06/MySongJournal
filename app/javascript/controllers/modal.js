// ✅ モーダルを開く関数
function openSpotifyModal() {
  const spotifyModal = document.getElementById('spotify-modal');
  const modalContent = document.getElementById('spotify-modal-content');

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
        .then(module => {
          module.initializeSearchConditions();
        })
        .catch(error => {
          console.error('モジュールの読み込みに失敗しました:', error);
        });

      // 年代トグル初期化
      import('./spotify_year_toggle.js')
        .then(module => {
          module.initializeYearToggle();
        })
        .catch(error => {
          console.error('モジュールの読み込みに失敗しました:', error);
        });
    })
    .catch(error => {
      modalContent.innerHTML = '<p class="text-red-500">検索フォームの読み込みに失敗しました。</p>';
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
