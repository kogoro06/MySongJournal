// 🎯 Spotify オートコンプリート
export function initializeSpotifyAutocomplete() {
  const searchConditionsContainer = document.getElementById('search-conditions');
  const abortControllers = new Map(); // 各フィールドごとのリクエスト管理

  // 🔄 検索条件ごとにイベントを追加
  function initializeAutoCompleteForField(queryField, typeField) {
    queryField.addEventListener('input', (event) => {
      const query = event.target.value.trim();
      const type = typeField.value;

      if (!query) {
        clearSuggestions(queryField);
        return;
      }

      // 既存のリクエストをキャンセル
      if (abortControllers.has(queryField)) {
        abortControllers.get(queryField).abort();
      }

      const controller = new AbortController();
      abortControllers.set(queryField, controller);

      fetch(`/spotify/autocomplete?query=${encodeURIComponent(query)}&type=${type}`, {
        signal: controller.signal,
      })
        .then(response => {
          if (!response.ok) throw new Error(`HTTPエラー: ${response.status}`);
          return response.json();
        })
        .then(data => {
          const uniqueSuggestions = filterUniqueSuggestions(data);
          renderSuggestions(uniqueSuggestions, queryField);
        })
        .catch(error => {
          if (error.name === 'AbortError') {
            console.log('🔄 リクエストがキャンセルされました:', queryField);
          } else {
            console.error('❌ APIリクエストエラー:', error);
          }
        });
    });
  }

  // 🎯 重複データを除去する関数
  function filterUniqueSuggestions(suggestions) {
    const seen = new Set();
    return suggestions.filter(suggestion => {
      if (seen.has(suggestion.name)) {
        return false;
      }
      seen.add(suggestion.name);
      return true;
    });
  }

  // 🎯 オートコンプリート候補の表示
  function renderSuggestions(suggestions, queryField) {
    let suggestionList = queryField.nextElementSibling;
    if (!suggestionList || suggestionList.tagName !== 'UL') {
      suggestionList = document.createElement('ul');
      suggestionList.classList.add(
        'autocomplete-list',
        'bg-white',
        'text-gray-800',
        'rounded-md',
        'shadow-md',
        'mt-2',
        'max-h-40',
        'overflow-y-auto'
      );
      queryField.insertAdjacentElement('afterend', suggestionList);
    }

    suggestionList.innerHTML = '';
    suggestions.forEach(suggestion => {
      const li = document.createElement('li');
      li.textContent = suggestion.name;
      li.classList.add('p-2', 'hover:bg-gray-100', 'cursor-pointer');
      li.addEventListener('click', () => {
        queryField.value = suggestion.name;
        suggestionList.innerHTML = '';
      });
      suggestionList.appendChild(li);
    });
  }

  // 🎯 オートコンプリート候補のクリア
  function clearSuggestions(queryField) {
    const suggestionList = queryField.nextElementSibling;
    if (suggestionList && suggestionList.tagName === 'UL') {
      suggestionList.innerHTML = '';
    }
  }

  // ✅ 初期検索条件のオートコンプリート
  const initialQueryField = document.getElementById('initial-query');
  const initialTypeField = document.getElementById('initial-search-type');
  if (initialQueryField && initialTypeField) {
    initializeAutoCompleteForField(initialQueryField, initialTypeField);
  }

  // ✅ 検索条件を追加
  const addConditionBtn = document.getElementById('add-condition-btn');
  if (addConditionBtn) {
    addConditionBtn.addEventListener('click', () => {
      setTimeout(() => {
        const newCondition = document.querySelector('.search-condition:last-child');
        const newQueryField = newCondition.querySelector('input');
        const newTypeField = newCondition.querySelector('select');

        if (newQueryField && newTypeField) {
          initializeAutoCompleteForField(newQueryField, newTypeField);
        } else {
          console.warn('⚠️ 新しい検索条件の入力フィールドまたはタイプフィールドが見つかりません。');
        }
      }, 200); // DOM更新後に実行
    });
  }

  // ✅ 動的に追加された検索条件にもオートコンプリートを適用
  searchConditionsContainer?.addEventListener('input', (event) => {
    if (event.target.matches('input[name="search_values[]"]')) {
      const queryField = event.target;
      const container = queryField.closest('.search-condition');
      const typeField = container.querySelector('select[name="search_conditions[]"]');

      if (queryField && typeField) {
        initializeAutoCompleteForField(queryField, typeField);
      }
    }
  });
}
