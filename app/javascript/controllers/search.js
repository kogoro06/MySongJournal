document.addEventListener('DOMContentLoaded', () => {
  const openModalButton = document.getElementById('open-search-modal');
  const reopenModalButton = document.getElementById('reopen-search-modal');
  const spotifyModal = document.getElementById('spotify-modal');
  const modalContent = document.getElementById('spotify-modal-content');

  // ✅ モーダルを開く
  function openSpotifyModal() {
    spotifyModal.showModal();

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
  }

  if (openModalButton) {
    openModalButton.addEventListener('click', openSpotifyModal);
  }

  if (reopenModalButton) {
    reopenModalButton.addEventListener('click', openSpotifyModal);
  }

  // ✅ 曲を選択後、ビューに動的に反映
  document.addEventListener('click', (event) => {
    if (event.target && event.target.matches('.select-track-btn')) {
      const trackData = JSON.parse(event.target.dataset.track);

      // フォーム要素に値を動的にセット
      document.querySelector('input[name="journal[artist_name]"]').value = trackData.artist_name || '';
      document.querySelector('input[name="journal[song_name]"]').value = trackData.song_name || '';
      document.querySelector('input[name="journal[album_image]"]').value = trackData.album_image || '';
      document.querySelector('input[name="journal[preview_url]"]').value = trackData.preview_url || '';

      // UI要素に動的にセット
      document.getElementById('selected-artist-name').textContent = trackData.artist_name || '未選択';
      document.getElementById('selected-song-name').textContent = trackData.song_name || '未選択';

      const albumImage = document.getElementById('selected-album-image');
      if (albumImage) {
        albumImage.src = trackData.album_image || '';
      }

      const audioPlayer = document.getElementById('selected-audio');
      if (audioPlayer) {
        audioPlayer.src = trackData.preview_url || '';
        audioPlayer.load();
      }

      // モーダルを閉じる
      spotifyModal.close();

      // ボタンを「曲を選びなおす」に変更
      openModalButton.style.display = 'none';
      reopenModalButton.style.display = 'block';
    }
  });

  // ✅ モーダルを閉じたら内容をリセット
  spotifyModal.addEventListener('close', () => {
    modalContent.innerHTML = '';
  });
});
