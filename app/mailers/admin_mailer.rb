class AdminMailer < ActionMailer::Base
  default from: ENV['SMTP_USER_NAME']

  def weekly
    return unless ENV['ADMIN_EMAIL']
    next_week = (Time.now..(Time.now + 7.days))
    last_week = (7.days.ago..Time.now)
    @meetings = Meeting.where(meeting_date: next_week)
    @feedbacks = Feedback.where(created_at: last_week)
    @member_count = Member.active.count
    @uptime_weeks = ((Date.today - Meeting.first.meeting_date).to_i / 7.0).floor
    mail(to: ENV['ADMIN_EMAIL'], subject: "Monitor S'UP at #{ENV['COMPANY_NAME']}")
  end
end
