// app/javascript/controllers/user_input.js

/** ✅ ユーザー入力の初期化 */
export function initializeUserInput() {
  console.log('✅ ユーザー入力の初期化開始');

  const queryInput = document.getElementById('initial-query');
  const searchTypeSelect = document.getElementById('initial-search-type');
  const autoCompleteList = document.getElementById('autoComplete_list');
  const queryContainer = document.getElementById('initial-query-container');

  if (!queryInput || !searchTypeSelect || !autoCompleteList) {
    console.warn('⚠️ 必要な要素が見つかりません。');
    return;
  }

  /** 🎯 入力イベントリスナー */
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
        .catch((error) => console.error('❌ APIエラー:', error));
    });
  }

  /** 🎯 候補リストのレンダリング */
  function renderSuggestions(suggestions) {
    autoCompleteList.innerHTML = '';
    suggestions.forEach((suggestion) => {
      const li = document.createElement('li');
      li.textContent = suggestion.name;
      li.classList.add('list-group-item');
      li.addEventListener('click', () => handleSuggestionSelection(suggestion));
      autoCompleteList.appendChild(li);
    });
  }

  /** 🎯 候補が選択されたとき */
  function handleSuggestionSelection(suggestion) {
    queryInput.value = suggestion.name;
    autoCompleteList.innerHTML = '';
    console.log('✅ 選択されたアイテム:', suggestion);
  }

  /** 🎯 検索タイプ変更イベント */
  function initializeSearchTypeChange() {
    searchTypeSelect.addEventListener('change', () => {
      const selectedValue = searchTypeSelect.value;
      if (selectedValue === 'year') {
        queryContainer.innerHTML = `
          <select name="search_values[]" id="initial-query" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
            <option value="">年代を選択</option>
            ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}">${2000 + i}</option>`).join('')}
          </select>
        `;
      } else {
        queryContainer.innerHTML = `
          <input type="text" name="initial_query" id="initial-query" placeholder="キーワードを入力"
            class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
        `;
      }

      const newQueryInput = document.getElementById('initial-query');
      if (newQueryInput) addInputEventListener(newQueryInput);
    });
  }

  /** 🎯 初期リスナー設定 */
  if (queryInput) addInputEventListener(queryInput);
  initializeSearchTypeChange();

  console.log('✅ ユーザー入力の初期化が完了しました');
}
