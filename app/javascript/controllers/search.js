document.addEventListener('click', (event) => {
  if (event.target.matches('.select-track-btn')) {
    const trackData = JSON.parse(event.target.dataset.track);

    // ✅ 入力フォームにデータをセット
    ['artist_name', 'song_name', 'album_image', 'preview_url'].forEach((key) => {
      const input = document.querySelector(`input[name="journal[${key}]"]`);
      if (input) input.value = trackData[key] || '';
    });

    // ✅ テキスト要素にデータをセット
    document.getElementById('selected-artist-name').textContent = trackData.artist_name || '未選択';
    document.getElementById('selected-song-name').textContent = trackData.song_name || '未選択';

    // ✅ アルバム画像の設定
    const albumImage = document.getElementById('selected-album-image');
    if (albumImage) {
      albumImage.src = trackData.album_image || '';
    }

    // ✅ オーディオ要素の設定
    const audioPlayer = document.getElementById('selected-audio');
    if (audioPlayer) {
      audioPlayer.src = trackData.preview_url || '';
      audioPlayer.load();
    }

    // ✅ モーダルを閉じる
    const spotifyModal = document.getElementById('spotify-modal');
    if (spotifyModal) spotifyModal.close();

    // ✅ ボタンの表示切り替え
    const openModalButton = document.getElementById('open-search-modal');
    const reopenModalButton = document.getElementById('reopen-search-modal');
    if (openModalButton) openModalButton.style.display = 'none';
    if (reopenModalButton) reopenModalButton.style.display = 'block';
  }
});
