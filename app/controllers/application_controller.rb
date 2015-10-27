class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # BASIC auth
  before_filter :authenticate

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['SUP_USER_NAME'] && BCrypt::Password.new(ENV['SUP_PASSWORD_HASH']) == password
    end if ENV['SUP_USER_NAME']
  end
end
