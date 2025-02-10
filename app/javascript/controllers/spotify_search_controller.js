import { Controller } from "@hotwired/stimulus"

/**
 * Spotify検索機能を制御するStimulusコントローラー
 * 検索条件の追加/削除や入力フィールドの切り替えを管理
 */
export default class extends Controller {
  static targets = ["conditionContainer"]

  /**
   * コントローラーが接続された時に呼ばれる
   */
  connect() {
    console.log("Spotify Search Controller Connected")
    // 既存の検索フィールドにオートコンプリートを設定
    import('../controllers/spotify_autocomplete.js')
      .then(module => {
        module.initializeSpotifyAutocomplete();
      })
      .catch(error => {
        console.error('オートコンプリートの初期化エラー:', error);
      });
  }

  /**
   * 検索タイプの変更に応じて入力フィールドを切り替える
   * @param {Event} event - 変更イベント
   */
  toggleSearchInput(event) {
    const select = event.target
    const container = select.closest('.search-condition')
    const textInput = container.querySelector('.search-keyword-input')
    const decadeSelect = container.querySelector('.search-decade-select')
    
    // 入力値をクリア
    textInput.value = ''
    decadeSelect.value = ''
    
    // オートコンプリートの候補をクリア
    const datalist = textInput.getAttribute('list')
    if (datalist) {
      const datalistElement = document.getElementById(datalist)
      if (datalistElement) {
        datalistElement.innerHTML = ''
      }
    }
    
    // ul要素の候補リストもクリア
    const suggestionList = textInput.nextElementSibling
    if (suggestionList && suggestionList.tagName === 'UL') {
      suggestionList.remove()
    }
    
    // 検索タイプに応じてプレースホルダーを設定
    const placeholders = {
      'track': '曲名を入力',
      'artist': 'アーティスト名を入力',
      'keyword': 'キーワードを入力',
      'year': '年代を選択',
      '': '検索タイプを選択してください'
    }
    textInput.placeholder = placeholders[select.value] || placeholders['']
    
    if (select.value === 'year') {
      textInput.style.display = 'none'
      textInput.disabled = true
      decadeSelect.style.display = 'block'
      decadeSelect.disabled = false
    } else {
      textInput.style.display = 'block'
      textInput.disabled = false
      decadeSelect.style.display = 'none'
      decadeSelect.disabled = true
    }
    
    // 他の検索条件の選択肢を更新
    this.updateAvailableOptions()
  }

  updateAvailableOptions() {
    const conditions = document.querySelectorAll('.search-condition')
    const selectedValues = Array.from(conditions).map(condition => 
      condition.querySelector('.search-type-select').value
    )

    conditions.forEach((condition, index) => {
      const select = condition.querySelector('.search-type-select')
      Array.from(select.options).forEach(option => {
        if (option.value && option.value !== select.value) {
          option.disabled = selectedValues.includes(option.value)
        }
      })
    })
  }

  /**
   * 新しい検索条件フィールドを追加する
   * 最大2つまでの検索条件を許可
   * @param {Event} event - クリックイベント
   */
  addCondition(event) {
    event.preventDefault()
    const conditions = document.querySelectorAll('.search-condition')
    const newId = conditions.length
    
    if (newId < 2) {  // 最大2つまで
      const template = document.querySelector('.search-condition').cloneNode(true)
      template.dataset.conditionId = newId
      
      template.querySelectorAll('[id]').forEach(el => {
        el.id = el.id.replace(/\d+/, newId)
      })
      
      template.querySelectorAll('label').forEach(el => {
        const forAttr = el.getAttribute('for')
        if (forAttr) {
          el.setAttribute('for', forAttr.replace(/\d+/, newId))
        }
      })
      
      // 入力値をリセット
      template.querySelectorAll('input, select').forEach(el => {
        if (el.classList.contains('search-decade-select')) {
          el.style.display = 'none'
          el.disabled = true
          el.value = '1960s'  // デフォルト値を設定
        } else if (el.classList.contains('search-keyword-input')) {
          el.style.display = 'block'
          el.disabled = false
          el.value = ''
        } else if (el.classList.contains('search-type-select')) {
          el.value = ''
          // 既に選択されている検索タイプを無効化
          const selectedType = document.querySelector('.search-condition').querySelector('.search-type-select').value
          if (selectedType) {
            Array.from(el.options).find(opt => opt.value === selectedType).disabled = true
          }
        }
      })
      
      document.getElementById('search-conditions').appendChild(template)
    }
  }

  /**
   * 最後の検索条件フィールドを削除する
   * 最低1つの検索条件は常に維持
   * @param {Event} event - クリックイベント
   */
  removeCondition(event) {
    event.preventDefault()
    const conditions = document.querySelectorAll('.search-condition')
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove()
      this.updateAvailableOptions()
    }
  }

  selectTrack(event) {
    const track = event.currentTarget.dataset;
    
    // フォームに値をセット
    this.songNameTarget.value = track.songName;
    this.artistNameTarget.value = track.artistName;
    this.albumImageTarget.value = track.albumImage;
    this.previewUrlTarget.value = track.previewUrl;
    this.spotifyTrackIdTarget.value = track.spotifyTrackId;

    // ジャンルを自動判定
    this.determineGenre(track.artistName, track.songName, track.spotifyTrackId);

    // モーダルを閉じる
    this.closeModal();
  }

  async determineGenre(artistName, songName, trackId) {
    // アニメ/特撮の判定（クライアントサイド）
    if (this.isAnimeOrTokusatsu(artistName, songName)) {
      this.genreTarget.value = 'anime';
      return;
    }

    if (!trackId) {
      this.genreTarget.value = '';
      return;
    }

    try {
      // アーティストの情報を取得
      const response = await fetch(`/api/spotify/artist_genres?track_id=${trackId}`);
      if (!response.ok) throw new Error('Failed to fetch artist genres');
      
      const data = await response.json();
      if (data.genre) {
        this.genreTarget.value = data.genre;
      } else {
        this.genreTarget.value = '';
      }
    } catch (error) {
      console.error('Error determining genre:', error);
      this.genreTarget.value = '';
    }
  }

  isAnimeOrTokusatsu(artistName, songName) {
    const animePatterns = [
      /仮面ライダー|スーパー戦隊|戦隊|ウルトラマン|プリキュア|特撮|アニメ|disney|ディズニー|ジブリ|pixar|ピクサー/i,
      /山寺宏一|水木一郎|堀江美都子|ささきいさお|串田アキラ|影山ヒロノブ|池田直樹|遠藤正明|宮内タカユキ|高橋秀幸|松本梨香|林原めぐみ|水樹奈々|田村ゆかり|堀江由衣|中川翔子|JAM Project|きただにひろし|米倉千尋|奥井雅美|鮎川麻弥|堀江晶太|岡崎律子|GRANRODEO|angela|fripSide|May'n|藍井エイル|LiSA|ClariS|小倉唯|沢城みゆき|花澤香菜|戸松遥/i
    ];

    return animePatterns.some(pattern => 
      pattern.test(artistName) || pattern.test(songName)
    );
  }

  toggleDecade(event) {
    const radio = event.target
    const span = radio.nextElementSibling.nextElementSibling
    const hiddenInput = radio.nextElementSibling
    
    // 他の全てのラジオボタンのスタイルをリセット
    document.querySelectorAll('.decade-radio').forEach(r => {
      const otherSpan = r.nextElementSibling.nextElementSibling
      const otherHidden = r.nextElementSibling
      if (r !== radio) {
        otherSpan.classList.remove('bg-white', 'text-customblue')
        otherSpan.classList.add('text-white')
        otherHidden.disabled = true
      }
    })
    
    // 選択されたラジオボタンのスタイルを更新
    if (radio.checked) {
      span.classList.add('bg-white', 'text-customblue')
      span.classList.remove('text-white')
      hiddenInput.disabled = false
    }
    
    // フォームを自動送信
    radio.closest('form').requestSubmit()
  }
}