/**
 * Spotifyのオートコンプリート機能を初期化する
 * 検索フィールドに入力があった際に、Spotify APIから候補を取得して表示する
 */
export function initializeSpotifyAutocomplete() {
  // 検索条件を格納するコンテナ要素
  const searchConditionsContainer = document.getElementById('search-conditions');
  // 各検索フィールドのリクエストを管理するMap
  const abortControllers = new Map();

  /**
   * 検索フィールドごとにオートコンプリートを初期化する
   * @param {HTMLElement} queryField - 検索クエリの入力フィールド
   * @param {HTMLElement} typeField - 検索タイプの選択フィールド
   */
  function initializeAutoCompleteForField(queryField, typeField) {
    queryField.addEventListener('input', (event) => {
      const query = event.target.value.trim();
      const type = typeField.value;

      if (!query) {
        console.log('ℹ️ クエリが空です。候補をクリアします。');
        clearSuggestions(queryField);
        return;
      }

      // 進行中のリクエストがあればキャンセル
      if (abortControllers.has(queryField)) {
        const controller = abortControllers.get(queryField);
        controller.abort();
      }

      // 新しいリクエストのためのAbortControllerを作成
      const controller = new AbortController();
      abortControllers.set(queryField, controller);

      console.log(`🔍 オートコンプリートリクエスト: query="${query}", type="${type}"`);

      // Spotify APIに候補を問い合わせ
      fetch(`/spotify/autocomplete?query=${encodeURIComponent(query)}&type=${type}`, {
        signal: controller.signal,
      })
        .then(response => {
          if (!response.ok) {
            throw new Error(`HTTPエラー: ${response.status}`);
          }
          return response.json();
        })
        .then(data => {
          if (data.length === 0) {
            console.log('ℹ️ 検索結果なし。候補をクリアします。');
            clearSuggestions(queryField);
            return;
          }

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

  /**
   * 候補から重複を除去する
   * @param {Array} suggestions - APIから返された候補の配列
   * @returns {Array} 重複を除去した候補の配列
   */
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

  /**
   * オートコンプリートの候補リストを表示する
   * @param {Array} suggestions - 表示する候補の配列
   * @param {HTMLElement} queryField - 検索クエリの入力フィールド
   */
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

  /**
   * オートコンプリートの候補リストをクリアする
   * @param {HTMLElement} queryField - 検索クエリの入力フィールド
   */
  function clearSuggestions(queryField) {
    const suggestionList = queryField.nextElementSibling;
    if (suggestionList && suggestionList.tagName === 'UL') {
      suggestionList.innerHTML = '';
    }
  }

  // 初期検索条件のオートコンプリートを設定
  const initialQueryField = document.getElementById('initial-query');
  const initialTypeField = document.getElementById('initial-search-type');
  if (initialQueryField && initialTypeField) {
    initializeAutoCompleteForField(initialQueryField, initialTypeField);
  }

  // 検索条件追加ボタンのイベントハンドラを設定
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
      }, 200); // DOM更新を待つ
    });
  }

  // 動的に追加された検索条件のイベントを委譲して処理
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
