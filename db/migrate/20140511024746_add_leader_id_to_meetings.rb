class AddLeaderIdToMeetings < ActiveRecord::Migration
  def change
    add_column :meetings, :leader_id, :integer
  end
end
