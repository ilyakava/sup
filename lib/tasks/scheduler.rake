desc "schedule all meetings for the week"
task :update_feed => :environment do
  puts "Scheduling meetings..."
  Meeting.schedule_all
  puts "Done Scheduling meetings."
end

desc "mail all meetings for the week to admin for debug checking"
task :trigger_weekly_debug_email => :environment do
  puts "Sending weekly debug email..."
  Meeting.trigger_weekly_debug_email
  puts "Done sending weekly debug email..."
end

desc "mail all meetings for the week to meeting members"
task :trigger_weekly_email => :environment do
  puts "Sending weekly email..."
  Meeting.trigger_weekly_email
  puts "Done sending weekly email..."
end