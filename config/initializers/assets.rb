# Be sure to restart your server when you modify this file.
# このファイルを変更するときは、必ずサーバーを再起動してください。

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.追加のアセットをプリコンパイルします。
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# application.js、application.css、および app/assets フォルダー内のすべての非 JS/CSS はすでに追加されています。
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += %w( application.scss bootstrap.min.js popper.js )
