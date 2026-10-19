# ログイン中のユーザー自身のプロフィール（表示・編集 → 確認 → 保存）
class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_form_selections, only: [:edit, :update, :confirm]

  def show
  end

  def edit
    # 確認画面から「変更に戻る」で戻ってきた場合はセッションの入力値を復元する
    if session[:profile_params].present?
      @user.assign_attributes(session.delete(:profile_params))
    end
  end

  # edit のフォームの送信先。検証を通れば確認画面を表示する
  def confirm
    # @submitted_params : 元の送信値（hidden fields で update に渡すために保持）
    # valid? 後に year_of_birth 等の仮想属性がクリアされる場合があるため、事前に保存する
    @submitted_params = profile_params.to_h
    @user.assign_attributes(profile_params)
    if @user.valid?
      # 「変更に戻る」ボタン用にセッションへ入力値を保存しておく
      session[:profile_params] = @submitted_params
      render :confirm
    else
      flash.now[:danger] = "入力内容をご確認ください。"
      render :edit, status: :unprocessable_entity
    end
  end

  # 確認画面の「保存する」から呼ばれる
  def update
    session.delete(:profile_params)
    if @user.update(profile_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to root_path
    else
      flash.now[:danger] = "更新に失敗しました。入力内容をご確認ください。"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user # 操作対象は常にログインしているユーザー
  end

  # セレクトボックス用の選択肢を用意（年・月・日・都道府県）
  def set_form_selections
    @years  = (1900..Date.today.year).to_a.reverse
    @months = (1..12).to_a
    @days   = (1..31).to_a
    @prefectures = %w[
      北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県 茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県
      新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県 三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県
      鳥取県 島根県 岡山県 広島県 山口県 徳島県 香川県 愛媛県 高知県 福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県
    ]
  end

  # email は Devise の画面で変える。氏名・氏名カナ・生年月日は、モデルで姓・名などから組み立てる
  def profile_params
    params.require(:user).permit(
      :last_name,             # 姓
      :first_name,            # 名
      :last_name_kana,        # 姓カナ
      :first_name_kana,       # 名カナ
      :gender,                # 性別（1:男 2:女 3:回答しない）
      :year_of_birth,         # 誕生年（セレクト）
      :month_of_birth,        # 誕生月（セレクト）
      :day_of_birth,          # 誕生日（セレクト）
      :phone,                 # 電話番号（必要なら利用）
      :fixed_phone,           # 固定電話
      :mobile_phone,          # 携帯電話
      :address,               # 住所（合成で設定）
      :postal_code,           # 郵便番号
      :prefecture,            # 都道府県（セレクト）
      :city,                  # 市区町村
      :street_name,           # 町名
      :house_number,          # 番地
      :building_name,         # 建物名
      :apartment_number,      # 部屋番号
      :hobbies,               # 趣味
      :special_skills,        # 特技
      :note                   # 備考
    )
  end
end