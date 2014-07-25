ActionMailer::Base.smtp_settings = {
  :address              => ENV['SMTP_ADDRESS'] || "smtp.gmail.com",
  :port                 => ENV['SMTP_PORT'] || 587,
  :domain               => ENV['SMTP_DOMAIN'],
  :user_name            => ENV['SMTP_USER_NAME'],
  :password             => ENV['SMTP_PASSWORD'],
  :authentication       => "plain",
  :enable_starttls_auto => true
}