/**
 * Spotify入力処理の初期化
 * 検索フィールドの設定とオートコンプリート機能を提供する
 */
export function initializeSpotifyInput() {
  console.log('✅ Spotify入力処理を初期化');

  // オートコンプリートの候補リストと検索関連の要素を取得
  let autoCompleteList = document.getElementById('autoComplete_list');
  const queryContainer = document.getElementById('initial-query-container');
  const searchTypeSelect = document.getElementById('initial-search-type');

  // 必要な要素が存在しない場合は初期化を中止
  if (!queryContainer || !searchTypeSelect) {
    console.warn('⚠️ 必要な要素が見つかりません。');
    return;
  }

  /**
   * 入力フィールドにイベントリスナーを追加
   * 入力値に応じてSpotify APIから候補を取得する
   * @param {HTMLElement} inputElement - 入力フィールド要素
   */
  function addInputEventListener(inputElement) {
    inputElement.addEventListener('input', (event) => {
      const query = event.target.value.trim();

      // 入力が空の場合は候補をクリア
      if (!query) {
        autoCompleteList.innerHTML = '';
        return;
      }

      // Spotify APIに候補を問い合わせ
      fetch(`/spotify/autocomplete?query=${encodeURIComponent(query)}`)
        .then((response) => {
          if (!response.ok) {
            throw new Error(`HTTPエラー: ${response.status}`);
          }
          return response.json();
        })
        .then((data) => renderSuggestions(data))
        .catch((error) => console.error('❌ APIリクエストエラー:', error));
    });
  }

  /**
   * 検索候補をリストとして表示
   * @param {Array} suggestions - 表示する候補の配列
   */
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

  /**
   * 候補が選択された時の処理
   * 選択された候補を入力フィールドに設定
   * @param {Object} suggestion - 選択された候補オブジェクト
   */
  function handleSelection(suggestion) {
    const queryInput = document.getElementById('initial-query');
    if (queryInput) {
      queryInput.value = suggestion.name;
      autoCompleteList.innerHTML = '';
    }
  }

  // 新しい要素の取得とイベントリスナーの再設定
  const newQueryInput = document.getElementById('initial-query');
  autoCompleteList = document.getElementById('autoComplete_list');

  console.log('🔍 新しい初期入力フィールド:', newQueryInput);
  console.log('🔍 新しいオートコンプリートリスト:', autoCompleteList);

  // 新しい要素が存在する場合はイベントリスナーを設定
  if (newQueryInput && autoCompleteList) {
    addInputEventListener(newQueryInput);
    console.log('✅ 新しい入力フィールドにイベントリスナーが設定されました');
  } else {
    console.error('❌ 新しい #initial-query または #autoComplete_list が見つかりません。');
  }
};

// 初期入力フィールドにイベントリスナーを設定
const initialQueryInput = document.getElementById('initial-query');
if (initialQueryInput) {
  addInputEventListener(initialQueryInput);
  console.log('✅ 初期入力フィールドにイベントリスナーが設定されました');
}