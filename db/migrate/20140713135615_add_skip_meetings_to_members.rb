class AddSkipMeetingsToMembers < ActiveRecord::Migration
  def change
    add_column :members, :skip_meetings, :boolean, null: false, default: false
  end
end
