require 'rails_helper'

RSpec.describe 'StaticPages', type: :request do
  describe 'GET /' do
    it '正常にレスポンスを返すこと' do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /help' do
    it '正常にレスポンスを返すこと' do
      get help_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /about' do
    it '正常にレスポンスを返すこと' do
      get about_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /contact' do
    it '正常にレスポンスを返すこと' do
      get contact_path
      expect(response).to have_http_status(:ok)
    end
  end
end
