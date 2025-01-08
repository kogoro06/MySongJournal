// app/javascript/controllers/spotify_input.js

/** ✅ Spotify入力処理の初期化 */
export function initializeSpotifyInput() {
  console.log('✅ Spotify入力処理を初期化');

  const autoCompleteList = document.getElementById('autoComplete_list');
  const queryContainer = document.getElementById('initial-query-container');
  const searchTypeSelect = document.getElementById('initial-search-type');

  if (!queryContainer || !searchTypeSelect) {
    console.warn('⚠️ 必要な要素が見つかりません。');
    return;
  }

  /** 🎯 入力リスナー追加 */
  function addInputEventListener(inputElement) {
    inputElement.addEventListener('input', (event) => {
      const query = event.target.value.trim();

      if (!query) {
        autoCompleteList.innerHTML = '';
        return;
      }

      fetch(`/spotify_search?query=${encodeURIComponent(query)}`)
        .then((response) => response.json())
        .then((data) => renderSuggestions(data.suggestions))
        .catch((error) => console.error('❌ APIリクエストエラー:', error));
    });
  }

  /** 🎯 検索結果のレンダリング */
  function renderSuggestions(suggestions) {
    autoCompleteList.innerHTML = '';
    suggestions.forEach((suggestion) => {
      const li = document.createElement('li');
      li.textContent = suggestion.name;
      li.classList.add('list-group-item');
      li.addEventListener('click', () => handleSelection(suggestion));
      autoCompleteList.appendChild(li);
    });
  }

  /** 🎯 候補選択処理 */
  function handleSelection(suggestion) {
    const queryInput = document.getElementById('initial-query');
    if (queryInput) {
      queryInput.value = suggestion.name;
      autoCompleteList.innerHTML = '';
    }
  }

  /** 🎯 検索タイプ変更 */
  searchTypeSelect.addEventListener('change', () => {
    const selectedValue = searchTypeSelect.value;
    if (selectedValue === 'year') {
      queryContainer.innerHTML = `
        <select name="search_values[]" id="initial-query" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
          <option value="">年代を選択</option>
          ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}">${2000 + i}</option>`).join('')}
        </select>`;
    } else {
      queryContainer.innerHTML = `
        <input type="text" name="initial_query" id="initial-query" placeholder="キーワードを入力"
          class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">`;
    }

    const newQueryInput = document.getElementById('initial-query');
    if (newQueryInput) addInputEventListener(newQueryInput);
  });

  /** 🎯 初期リスナー設定 */
  const initialQueryInput = document.getElementById('initial-query');
  if (initialQueryInput) addInputEventListener(initialQueryInput);
}
