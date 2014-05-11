class RemoveLeaderIdFromMembers < ActiveRecord::Migration
  def change
    remove_column :members, :leader_id, :string
  end
end
