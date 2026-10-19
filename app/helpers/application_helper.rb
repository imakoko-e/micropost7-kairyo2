module ApplicationHelper

  # ページごとの完全なタイトルを返す
  def full_title(page_title = '')
    base_title = "Micropost7"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  # いま開いている画面のメニュー項目に active を付ける
  def active_if(path, action)
    (path == controller_path && action == action_name) ? 'active' : ''
  end

  # 渡されたユーザーがログイン中のユーザーなら true
  def current_user?(user)
    user && user == current_user
  end

  # 検証エラーを { 項目名 => ["項目の表示名＋メッセージ", …] } の形にする
  # resource には検証したモデルのインスタンスを渡す
  def errors_hash(resource)
    resource.errors.messages.map do |col, errors_array|
      [col, errors_array.map { |error| resource.class.human_attribute_name(col) + error }]
    end.to_h
  end

  # 入力欄ごとに、その項目のエラーメッセージを欄の下に表示するフォームビルダー
  class CustomFormBuilder < ActionView::Helpers::FormBuilder
    def text_field(method, options = {})
      super + error_message(method)
    end

    def text_area(method, options = {})
      super + error_message(method)
    end

    def email_field(method, options = {})
      super + error_message(method)
    end

    def password_field(method, options = {})
      super + error_message(method)
    end

    # select は html_options とブロックも受け取り、そのまま親へ渡す
    def select(method, choices = nil, options = {}, html_options = {}, &block)
      super(method, choices, options, html_options, &block) + error_message(method)
    end

    def collection_radio_buttons(method, collection, value_method, text_method, options = {})
      super + error_message(method)
    end

    private

    def error_message(method)
      return if @object.errors[method].blank?
      @template.content_tag(:div, class: 'error_message') do
        @object.errors.full_messages_for(method).each do |msg|
          @template.concat(@template.content_tag(:span, msg))
        end
      end
    end
  end

  # 入力欄のあとに、エラーがあれば error-class の div でメッセージを足すフォームビルダー
  class FormBuilderWithErrorMsg < ActionView::Helpers::FormBuilder
    def text_field(attribute, options={})
      input_field_with_error(attribute, options) do
         super
      end
    end

    def email_field(attribute, options={})
      input_field_with_error(attribute, options) do
        super
      end
    end

    def password_field(attribute, options={})
      input_field_with_error(attribute, options) do
        super
      end
    end

    # 入力欄（block）と、その項目のエラーメッセージ（あれば）をつなげて返す
    def input_field_with_error(attribute, options={}, &block)
      error_messages = @object.errors.full_messages_for(attribute)

      if error_messages.any?
        error_contents = create_error_div(attribute, error_messages)
      end

      block.call + error_contents || ""
    end

    def create_error_div(attribute, messages)
      @template.content_tag(:div, class: "error-class") do
        messages.each do |message|
          @template.concat(@template.content_tag(:div, message))
        end
      end
    end

  end
end
