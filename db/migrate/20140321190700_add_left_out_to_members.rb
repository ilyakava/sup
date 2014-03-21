class AddLeftOutToMembers < ActiveRecord::Migration
  def change
    add_column :members, :left_out, :boolean
  end
end
