class RemoveIconUrlFromMembers < ActiveRecord::Migration
  def change
    remove_column :members, :icon_url, :string
  end
end
