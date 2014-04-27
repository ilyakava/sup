desc "schedule all meetings for the week"
task :schedule_meetings => :environment do
  if Time.now.friday?
    puts "Scheduling meetings..."
    Meeting.schedule_all
    puts "Done Scheduling meetings."
  end
end

desc "mail all meetings for the week to admin for debug checking"
task :trigger_weekly_debug_email => :environment do
  if Time.now.saturday?
    puts "Sending weekly debug email..."
    Meeting.trigger_weekly_debug_email
    puts "Done sending weekly debug email..."
  end
end

desc "mail all meetings for the week to meeting members"
task :trigger_weekly_email => :environment do
  if Time.now.sunday?
    puts "Sending weekly email..."
    Meeting.trigger_weekly_email
    puts "Done sending weekly email..."
  end
end