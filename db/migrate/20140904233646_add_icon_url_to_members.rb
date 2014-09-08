class AddIconUrlToMembers < ActiveRecord::Migration
  def change
    add_column :members, :icon_url, :string
  end
end
