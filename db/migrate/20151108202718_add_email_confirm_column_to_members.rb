class AddEmailConfirmColumnToMembers < ActiveRecord::Migration
  def change
    add_column :members, :email_confirmed, :boolean, :default => false
    add_column :members, :email_confirmation_token, :string
  end
end
