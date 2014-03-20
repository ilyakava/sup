class MeetingMember < ActiveRecord::Base
  belongs_to :member
  belongs_to :meeting
end
