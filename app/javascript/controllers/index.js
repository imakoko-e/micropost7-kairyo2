// controllers/ の下の *_controller.js を、importmap からすべて読み込んで登録する
// （新しいコントローラーは ./bin/rails generate stimulus <名前> で作る）
import { application } from "controllers/application"

import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

