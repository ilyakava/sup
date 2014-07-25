class MeetingMailer < ActionMailer::Base
  default from: ENV['SMTP_USER_NAME']

  def new_meeting(meeting)
    @meeting = meeting
    @members = meeting.members
    @times = [meeting.meeting_date]
    mail(to: @members.map(&:email), subject: "S'up with #{@members[0]}, #{@members[1]}, and #{@members[2]}?")
  end

  def followup(meeting)
    @meeting = meeting
    members = meeting.members
    @member = meeting.leader
    mail(to: @member.email, subject: "re: S'up with #{members[0]}, #{members[1]}, and #{members[2]}?")
  end
end
