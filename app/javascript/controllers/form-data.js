document.addEventListener('DOMContentLoaded', function() {
    // フォーム要素の取得
    const titleField = document.getElementById('journal-title');
    const emotionField = document.getElementById('journal-emotion');
    const contentField = document.getElementById('journal-content');
    const songNameField = document.getElementById('journal-song-name');
    const artistNameField = document.getElementById('journal-artist-name');
    const albumImageField = document.getElementById('journal-album-image');
    const previewUrlField = document.getElementById('journal-preview-url');
    const spotifyTrackIdField = document.getElementById('journal-spotify-track-id');
  
    // フォーム送信前にセッションストレージに保存
    document.getElementById('journal-form').addEventListener('submit', function() {
      saveFormData();
    });
  
    // セッションストレージからデータを読み込んでフォームに設定
    loadFormData();
  
    // 曲情報が選ばれたときにフォームに反映
    const selectSongButton = document.getElementById('open-search-modal');
    selectSongButton.addEventListener('click', function() {
      // 曲情報を選んだ時に更新
      // ここでは例として固定の値を使っていますが、Spotify APIのレスポンスを基に値を設定します
      const selectedSong = {
        songName: 'Bussin\'',
        artistName: 'AK-69, Yellow Bucks',
        albumImage: 'https://linktoalbumimage.com/album.jpg',
        previewUrl: 'https://linktopreview.com/preview.mp3',
        spotifyTrackId: 'some-track-id'
      };
  
      // 既存の値と一緒に曲情報を反映
      titleField.value = titleField.value || '';  // タイトルは上書きしない
      emotionField.value = emotionField.value || '';  // 感情は上書きしない
      contentField.value = contentField.value || '';  // 本文も上書きしない
  
      songNameField.value = selectedSong.songName;
      artistNameField.value = selectedSong.artistName;
      albumImageField.src = selectedSong.albumImage;
      previewUrlField.value = selectedSong.previewUrl;
      spotifyTrackIdField.value = selectedSong.spotifyTrackId;
  
      // フォームデータをセッションストレージに保存
      saveFormData();
    });
  
    function saveFormData() {
      // フォームのデータをセッションストレージに保存
      sessionStorage.setItem('journalTitle', titleField.value);
      sessionStorage.setItem('journalEmotion', emotionField.value);
      sessionStorage.setItem('journalContent', contentField.value);
      sessionStorage.setItem('journalSongName', songNameField.value);
      sessionStorage.setItem('journalArtistName', artistNameField.value);
      sessionStorage.setItem('journalAlbumImage', albumImageField.src);
      sessionStorage.setItem('journalPreviewUrl', previewUrlField.value);
      sessionStorage.setItem('journalSpotifyTrackId', spotifyTrackIdField.value);
    }
  
    function loadFormData() {
      // セッションストレージからデータを取得
      const savedTitle = sessionStorage.getItem('journalTitle');
      const savedEmotion = sessionStorage.getItem('journalEmotion');
      const savedContent = sessionStorage.getItem('journalContent');
      const savedSongName = sessionStorage.getItem('journalSongName');
      const savedArtistName = sessionStorage.getItem('journalArtistName');
      const savedAlbumImage = sessionStorage.getItem('journalAlbumImage');
      const savedPreviewUrl = sessionStorage.getItem('journalPreviewUrl');
      const savedSpotifyTrackId = sessionStorage.getItem('journalSpotifyTrackId');
  
      // フォームにデータを反映
      if (savedTitle) {
        titleField.value = savedTitle;
      }
      if (savedEmotion) {
        emotionField.value = savedEmotion;
      }
      if (savedContent) {
        contentField.value = savedContent;
      }
      if (savedSongName) {
        songNameField.value = savedSongName;
      }
      if (savedArtistName) {
        artistNameField.value = savedArtistName;
      }
      if (savedAlbumImage) {
        albumImageField.src = savedAlbumImage;
      }
      if (savedPreviewUrl) {
        previewUrlField.value = savedPreviewUrl;
      }
      if (savedSpotifyTrackId) {
        spotifyTrackIdField.value = savedSpotifyTrackId;
      }
    }
  });
  