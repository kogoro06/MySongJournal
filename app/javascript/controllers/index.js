// 🔄 このファイルは自動生成されます
// ./bin/rails stimulus:manifest:update コマンドで生成
// 新しいコントローラーを追加する際や、
// ./bin/rails generate stimulus controllerName でコントローラーを作成する際に実行してください

import { application } from "./application"

// 🔐 パスワードの表示/非表示を切り替えるコントローラー
import PasswordVisibilityController from "./password_visibility_controller"
application.register("password-visibility", PasswordVisibilityController)
