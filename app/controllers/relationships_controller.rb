class RelationshipsController < ApplicationController
  before_action :authenticate_user!

  def create
    @user = User.find(params[:followed_id])
    current_user.follow(@user)
    
    # 通常のリクエストは画面を移り、Turbo のリクエストは create.turbo_stream.erb で
    # フォローのボタンと人数だけを差し替える（実行されるのはどちらか一方）
    respond_to do |format|
      format.html { redirect_to @user }
      format.turbo_stream
    end
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow(@user)
    
    respond_to do |format|
      format.html { redirect_to @user, status: :see_other }
      format.turbo_stream   # destroy.turbo_stream.erb
    end
  end
end
