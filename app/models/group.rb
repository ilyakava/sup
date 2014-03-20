class Group < ActiveRecord::Base
  has_many :group_members
  has_many :members, through: :group_members

  attr_accessible :name
end
