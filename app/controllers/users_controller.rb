class UsersController < ApplicationController
  # ログイン必須（一覧・詳細・フォロー一覧・フォロワー一覧）
  # Devise の authenticate_user! を使う（スマホでのエラーを避けるため）
  before_action :authenticate_user!, only: [:index, :show, :following, :followers]

  def index
    @users = User.paginate(page: params[:page])
  end

  def show

    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def following
    @title = "フォロー ユーザー 一覧"
    @user  = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow', status: :unprocessable_entity  # Turbo 用に status を指定
  end

  def followers
    @title = "フォロワー 一覧"
    @user  = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow', status: :unprocessable_entity  # Turbo 用に status を指定
  end
end
