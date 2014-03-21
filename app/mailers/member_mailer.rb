class MemberMailer < ActionMailer::Base
  default from: "sup@artsymail.com"

  def welcome_email(member)
    @member = member
    mail(to: @member.email, subject: "Welcome to S'UP at Artsy")
  end
end
