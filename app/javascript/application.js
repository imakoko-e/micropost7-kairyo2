// importmap の設定は config/importmap.rb（https://github.com/rails/importmap-rails）
import "@hotwired/turbo-rails"
// Stimulus のコントローラーをすべて読み込む
import "controllers"
// 画像の大きさを、アップロードの前に確かめる
import "custom/image_upload"
// Action Cable の接続（channels/consumer.js が作る）
import consumer from "channels/consumer"

// WebSocket の接続を見張り、切れたら1秒後につなぎ直す
document.addEventListener("turbo:load", () => {
    if (consumer.connection.monitor) {
        consumer.connection.monitor.start();
        consumer.connection.onDisconnected = () => {
            console.log("WebSocket が切断されました。 再接続中...");
            setTimeout(() => consumer.connection.reopen(), 1000);
        };
    }
});

