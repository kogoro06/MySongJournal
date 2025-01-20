import { Controller } from "@hotwired/stimulus"

/**
 * Spotify検索機能を制御するStimulusコントローラー
 * 検索条件の追加/削除や入力フィールドの切り替えを管理
 */
export default class extends Controller {
  /**
   * コントローラーが接続された時に呼ばれる
   */
  connect() {
    console.log("Spotify Search controller connected")
  }

  /**
   * 検索タイプの変更に応じて入力フィールドを切り替える
   * @param {Event} event - 変更イベント
   */
  toggleSearchInput(event) {
    console.log("toggleSearchInput called")
    const select = event.currentTarget
    const conditionId = select.closest('.search-condition').dataset.conditionId
    const queryContainer = document.getElementById(`query-container-${conditionId}`)
    const textInputContainer = queryContainer.querySelector('.text-input-container')
    const yearSelectContainer = queryContainer.querySelector('.year-select-container')

    // 年選択の場合はyearSelectを表示、それ以外はテキスト入力を表示
    if (select.value === 'year') {
      console.log("Switching to year select")
      textInputContainer.classList.add('hidden')
      yearSelectContainer.classList.remove('hidden')
      textInputContainer.querySelector('input').disabled = true
      yearSelectContainer.querySelector('select').disabled = false
    } else {
      console.log("Switching to text input")
      textInputContainer.classList.remove('hidden')
      yearSelectContainer.classList.add('hidden')
      textInputContainer.querySelector('input').disabled = false
      yearSelectContainer.querySelector('select').disabled = true
    }
  }

  /**
   * 新しい検索条件フィールドを追加する
   * 最大2つまでの検索条件を許可
   * @param {Event} event - クリックイベント
   */
  addCondition(event) {
    event.preventDefault()
    console.log("addCondition called")
    const conditions = document.querySelectorAll('.search-condition')
    const newId = conditions.length
    
    if (newId < 2) {  // 最大2つまで
      // 既存の検索条件をクローン
      const template = document.querySelector('.search-condition').cloneNode(true)
      template.dataset.conditionId = newId
      
      // 新しい要素のIDを更新
      template.querySelectorAll('[id]').forEach(el => {
        el.id = el.id.replace(/\d+/, newId)
      })

      // イベントリスナーを設定
      const newSelect = template.querySelector('.search-type-select');
      newSelect.setAttribute('data-action', 'change->spotify-search#toggleSearchInput');

      // フォーム要素をリセット
      template.querySelector('select').value = ''
      template.querySelector('input[type="text"]').value = ''
      template.querySelector('select[id^="year-select"]').value = ''

      // 表示状態を初期化
      const textInputContainer = template.querySelector('.text-input-container')
      const yearSelectContainer = template.querySelector('.year-select-container')
      textInputContainer.classList.remove('hidden')
      yearSelectContainer.classList.add('hidden')
      textInputContainer.querySelector('input').disabled = false
      yearSelectContainer.querySelector('select').disabled = true

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
    console.log("removeCondition called")
    const conditions = document.querySelectorAll('.search-condition')
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove()
    }
  }
}
