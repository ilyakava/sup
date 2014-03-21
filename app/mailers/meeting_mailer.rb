class MeetingMailer < ActionMailer::Base
  default from: 'sup@artsymail.com'

  def new_meeting(members, times)
    @members = members
    @times = times
    mail(to: @members.map(&:email), subject: "S'up with #{@members[0]}, #{@members[1]}, and #{@members[2]}?")
  end
end
