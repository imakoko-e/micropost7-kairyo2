# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

# customディレクトリにあるJavaScriptコードをImportmapの設定に追加
pin_all_from "app/javascript/custom",      under: "custom"

# Action Cable
pin "@rails/actioncable", to: "actioncable.esm.js"      # preload: true は通常不要
pin_all_from "app/javascript/channels", under: "channels" # channels/consumer.js