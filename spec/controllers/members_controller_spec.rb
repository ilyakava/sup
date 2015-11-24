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

  describe '.create' do
    let(:member) { Member.create!(name: 'John Doe', email: 'jd@artsymail.com', group_ids: [@group.id]) }
    before do
      @group = Group.create!(name: 'Design')
      @member = member
    end
    it 'checks registration email is sent' do
      expect { post :create, member: { name: 'John Doe', email: 'jd1@artsymail.com', skip_meetings: 0, group_ids: [@group.id] } }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it 'verifies email and sends welcome email' do
      expect { get :verify_email, id: @member.email_confirmation_token }.to change(ActionMailer::Base.deliveries, :count).by(1)
      @member = Member.find_by_email('jd@artsymail.com')
      expect(@member.email_confirmed).to be true
    end

    it 'verifies email using invalid token to check member state' do
      get :verify_email, id: 'random_1212'
      @member = Member.find_by_email('jd@artsymail.com')
      expect(@member.email_confirmed).to be false
    end
  end

  describe '.edit' do
    let(:member) { Member.create!(name: 'John Doe', email: 'jd@artsymail.com', group_ids: [@group.id]) }

    before do
      @group = Group.create!(name: 'Design')
      @member = member
    end

    it 'checks member who have not verified email yet does not have access' do
      get :edit, id: @member
      expect(response.status).to eq 302
    end
  end

  it 'redirects to 404 when a member is not found' do
    expect do
      get :edit, id: -1
    end.to raise_error(ActionController::RoutingError)
  end
end
