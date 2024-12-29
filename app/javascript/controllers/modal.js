document.addEventListener('DOMContentLoaded', () => {
    const openModalButton = document.getElementById('open-search-modal');
    const spotifyModal = document.getElementById('spotify-modal');
    const modalContent = document.getElementById('spotify-modal-content');
  
    // モーダルを開く
    openModalButton.addEventListener('click', () => {
      spotifyModal.showModal();
  
      // 検索フォームを動的にロード
      fetch('/spotify/search', {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
      })
        .then(response => response.text())
        .then(html => {
          modalContent.innerHTML = html;
        })
        .catch(error => {
          console.error('検索フォームの読み込み中にエラーが発生しました:', error);
          modalContent.innerHTML = '<p class="text-red-500">検索フォームの読み込みに失敗しました。</p>';
        });
    });
  
    // モーダルを閉じたら内容をリセット
    spotifyModal.addEventListener('close', () => {
      modalContent.innerHTML = '';
    });
  });
  