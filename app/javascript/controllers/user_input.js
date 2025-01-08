// app/javascript/controllers/user_input.js

export function initializeUserInput() {
    console.log('✅ ユーザー入力の初期化開始');
  
    const autoCompleteList = document.getElementById('autoComplete_list');
  
    // 入力フィールドのイベントリスナーを追加する関数
    function addInputEventListener(queryInput) {
      queryInput.addEventListener('input', function (event) {
        const query = event.target.value.trim();
  
        if (query === '') {
          autoCompleteList.innerHTML = '';
          return;
        }
  
        // APIリクエストを送信
        fetch(`/spotify_search?query=${query}`)
          .then((response) => response.json())
          .then((data) => {
            const suggestions = data.suggestions;
            renderSuggestions(suggestions);
          })
          .catch((error) => console.error('Error fetching data:', error));
      });
    }
  
    // オートコンプリートリストをレンダリング
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
  
    // 候補がクリックされた時の処理
    function handleSelection(suggestion) {
      const queryInput = document.getElementById('initial-query');
      queryInput.value = suggestion.name;
      autoCompleteList.innerHTML = '';
    }
  
    // 初期状態で input イベントリスナーを追加
    const initialQueryInput = document.getElementById('initial-query');
    if (initialQueryInput) {
      addInputEventListener(initialQueryInput);
    }
  
    // 検索タイプ変更時に入力フィールドを動的に切り替える処理
    const searchTypeSelect = document.getElementById('initial-search-type');
    searchTypeSelect.addEventListener('change', function (event) {
      const selectedValue = event.target.value;
      const queryContainer = document.getElementById('initial-query-container');
  
      // 検索タイプ変更時に入力フィールドを更新
      if (selectedValue === 'year') {
        queryContainer.innerHTML = `
          <select name="search_values[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
            <option value="">年代を選択</option>
            ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}">${2000 + i}</option>`).join('')}
          </select>
        `;
      } else {
        queryContainer.innerHTML = `
          <input type="text" name="search_values[]" placeholder="キーワードを入力" class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700" id="initial-query">
        `;
      }
  
      // 新しく生成された input 要素にイベントリスナーを再設定
      const newQueryInput = document.getElementById('initial-query');
      if (newQueryInput) {
        addInputEventListener(newQueryInput);
      }
    });
  }
  