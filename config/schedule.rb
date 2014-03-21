# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every :friday, :at => '5am' do
  runner "Meeting.schedule_all"
end

every :friday, :at => '3pm' do
  runner "Meeting.trigger_weekly_debug_email"
end

every :sunday, :at => '11am' do
  runner "Meeting.trigger_weekly_email"
end