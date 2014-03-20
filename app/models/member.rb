class Member < ActiveRecord::Base
  has_many :group_members
  has_many :groups, through: :group_members

  has_many :meeting_members
  has_many :meetings, through: :meeting_members

  attr_accessible :name, :email
end
