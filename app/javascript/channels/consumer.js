// Action Cable（WebSocket）の接続。チャンネルの購読は各 Stimulus コントローラーで行う

import { createConsumer } from "@rails/actioncable"

// 接続先の URL は書かない（action_cable_meta_tag から読む。開発と本番で同じコードになる）
export default createConsumer()
