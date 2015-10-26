require 'spec_helper'

describe MembersController do
  describe '#graph' do
    context 'without SUP_USER_NAME' do
      it 'does not prompt for authentication' do
        get :index
        expect(response.status).to eq 200
      end
    end

    context 'with SUP_USER_NAME and SUP_PASSWORD_HASH' do
      before do
        ENV['SUP_USER_NAME'] = 'username'
        ENV['SUP_PASSWORD_HASH'] = BCrypt::Password.create('password')
      end

      after do
        ENV.delete 'SUP_USER_NAME'
        ENV.delete 'SUP_PASSWORD'
      end

      it 'prompts for HTTP Basic authentication' do
        get :index
        expect(response.status).to eq 401
      end

      it 'accepts correct username/password' do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('username', 'password')
        get :index
        expect(response.status).to eq 200
      end

      it 'denies access with incorrect username/password' do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('username', 'invalid')
        get :index
        expect(response.status).to eq 401
      end
    end
  end
end
