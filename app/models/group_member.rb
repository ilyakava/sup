class GroupMember < ActiveRecord::Base
  belongs_to :member
  belongs_to :group
end
