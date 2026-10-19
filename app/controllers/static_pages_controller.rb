class StaticPagesController < ApplicationController
  layout "application"

  def home
    if user_signed_in?
      # 投稿のフォームと、フィード
      @micropost  = current_user.microposts.build
      @feed_items = current_user.feed.paginate(page: params[:page])
    else
      @user = User.new            # ログインしていないときのフォーム（form_with）に渡す
    end
  end

  def help
  end

  def about
  end

  def contact
  end
end
