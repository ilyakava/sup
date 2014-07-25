class MemberMailer < ActionMailer::Base
  default from: ENV['SMTP_USER_NAME']

  def welcome_email(member)
    @member = member
    mail(to: @member.email, subject: "Welcome to S'UP at #{ENV['COMPANY_NAME']}")
  end
end
