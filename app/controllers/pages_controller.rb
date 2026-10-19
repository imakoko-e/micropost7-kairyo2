# 通知だけを表示する画面（layout は page）
class PagesController < ApplicationController
  layout 'page'

  def mail_check
    # メールを確認した直後の1回は、Timeoutable の判定を外す（自動ログアウトと誤判定しないため）
    request.env['devise.skip_timeout'] = true

    # タイトル・本文・種類は flash[:page] を優先し、無ければクエリパラメータから取る
    page = (flash[:page] || {}).with_indifferent_access   # 文字列キー／シンボルキーどちらでもアクセスできるように変換
    @title   = page[:title]   || params[:title]   || "== 通知 =="
    @message = page[:message] || params[:message] || ""
    @type    = page[:type]    || params[:type]    || "info"  # (例：success, danger など)

    # この後のリクエスト（/users/:id など）にflash[:page] を持ち越さない
    flash.discard(:page)
  end

end
