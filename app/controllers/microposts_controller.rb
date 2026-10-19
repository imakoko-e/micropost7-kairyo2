class MicropostsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :destroy]
  # 自分の投稿だけを消せる
  before_action :correct_user,   only: :destroy

  def create
    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image])
    if @micropost.save
      flash[:success] = "投稿されました！"
      redirect_to root_url
    else
      # Home の画面はフィード（@feed_items）を表示するので、失敗したときも渡す
      @feed_items = current_user.feed.paginate(page: params[:page])

      render 'static_pages/home', status: :unprocessable_entity
    end
  end

  def destroy
    @micropost.destroy
    flash[:success] = "投稿が削除されました"
    # 消した後は元の画面へ戻る（リファラーが無ければトップへ）
    if request.referrer.nil?
      redirect_to root_url, status: :see_other
    else
      redirect_to request.referrer, status: :see_other
    end
  end

  private

    def micropost_params
      params.require(:micropost).permit(:content, :image)
    end

    # 自分の投稿の中から探す。見つからなければトップへ
    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url, status: :see_other if @micropost.nil?
    end
end
