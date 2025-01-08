// app/javascript/controllers/spotify_autocomplete.js

/** ✅ Spotifyオートコンプリートの初期化 */
export function initializeSpotifyAutocomplete() {
  console.log("✅ initializeSpotifyAutocomplete が呼び出されました");

  const searchBox = document.getElementById('initial-query');
  const resultsList = document.getElementById('autoComplete_list');

  if (!searchBox || !resultsList) {
    console.warn('⚠️ 検索ボックスまたは検索結果リストが見つかりません。');
    return;
  }

  setupAutoComplete(searchBox, resultsList);
}

/** 🔄 AutoComplete の設定 */
function setupAutoComplete(searchBox, resultsList) {
  new autoComplete({
    selector: '#initial-query',
    data: {
      src: fetchAutoCompleteData,
      cache: false
    },
    resultsList: {
      render: true,
      container: resultsList,
    },
    resultItem: {
      highlight: true,
      content: renderResultItem,
    },
    events: {
      input: {
        selection: (event) => handleSelection(event, searchBox),
      }
    }
  });

  console.log('✅ AutoComplete.js が初期化されました');
}

/** 🔍 APIリクエスト */
async function fetchAutoCompleteData(query) {
  try {
    console.log('🔍 APIリクエスト: ', query);
    const response = await fetch(`/spotify/autocomplete?query=${encodeURIComponent(query)}`);
    if (!response.ok) throw new Error(`HTTPエラー: ${response.status}`);
    const data = await response.json();
    console.log('🔄 APIレスポンス: ', data);
    return data.map(item => ({
      name: `${item.name} (${item.artist || ''})`,
      id: item.id
    }));
  } catch (error) {
    console.error('❌ オートコンプリートAPIリクエストエラー:', error);
    return [];
  }
}

/** 📝 候補アイテムのレンダリング */
function renderResultItem(data, source) {
  source.innerHTML = `
    <div>
      <strong>${data.value.name}</strong>
    </div>
  `;
}

/** ✅ 候補選択時の処理 */
function handleSelection(event, searchBox) {
  const selection = event.detail.selection.value;
  searchBox.value = selection.name;
  console.log('✅ 選択されたアイテム:', selection);
}
