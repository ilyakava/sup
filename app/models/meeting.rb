class Meeting < ActiveRecord::Base
  has_many :meeting_members
  has_many :members, through: :meeting_members
end
