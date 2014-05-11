class AddLeaderIdToMembers < ActiveRecord::Migration
  def change
    add_column :members, :leader_id, :integer
  end
end
