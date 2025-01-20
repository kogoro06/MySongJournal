/** ✅ Spotify入力処理の初期化 */
export default class SpotifyInputController {
  constructor() {
    console.log('✅ Spotify入力処理を初期化');

    this.autoCompleteList = document.getElementById('autoComplete_list');
    this.queryContainer = document.getElementById('initial-query-container');
    this.searchTypeSelect = document.getElementById('initial-search-type');

    if (!this.queryContainer || !this.searchTypeSelect) {
      console.warn('⚠️ 必要な要素が見つかりません。');
      return;
    }

    /** 🎯 入力リスナー追加 */
    this.addInputEventListener = (inputElement) => {
      inputElement.addEventListener('input', (event) => {
        const query = event.target.value.trim();

        if (!query) {
          this.autoCompleteList.innerHTML = '';
          return;
        }

        fetch(`/spotify/autocomplete?query=${encodeURIComponent(query)}`)
          .then((response) => {
            if (!response.ok) {
              throw new Error(`HTTPエラー: ${response.status}`);
            }
            return response.json();
          })
          .then((data) => this.renderSuggestions(data))
          .catch((error) => console.error('❌ APIリクエストエラー:', error));
      });
    };

    /** 🎯 検索結果のレンダリング */
    this.renderSuggestions = (suggestions) => {
      this.autoCompleteList.innerHTML = '';
      suggestions.forEach((suggestion) => {
        const li = document.createElement('li');
        li.textContent = suggestion.name;
        li.classList.add('list-group-item');
        li.addEventListener('click', () => this.handleSelection(suggestion));
        this.autoCompleteList.appendChild(li);
      });
    };

    /** 🎯 候補選択処理 */
    this.handleSelection = (suggestion) => {
      const queryInput = document.getElementById('initial-query');
      if (queryInput) {
        queryInput.value = suggestion.name;
        this.autoCompleteList.innerHTML = '';
      }
    };

    // 新しい要素にイベントリスナーを再設定
    const newQueryInput = document.getElementById('initial-query');
    this.autoCompleteList = document.getElementById('autoComplete_list');

    console.log('🔍 新しい初期入力フィールド:', newQueryInput);
    console.log('🔍 新しいオートコンプリートリスト:', this.autoCompleteList);

    if (newQueryInput && this.autoCompleteList) {
      this.addInputEventListener(newQueryInput);
      console.log('✅ 新しい入力フィールドにイベントリスナーが設定されました');
    } else {
      console.error('❌ 新しい #initial-query または #autoComplete_list が見つかりません。');
    }
  }

  /** 🎯 初期リスナー設定 */
  initialize() {
    const initialQueryInput = document.getElementById('initial-query');
    if (initialQueryInput) {
      this.addInputEventListener(initialQueryInput);
      console.log('✅ 初期入力フィールドにイベントリスナーが設定されました');
    }
  }
}