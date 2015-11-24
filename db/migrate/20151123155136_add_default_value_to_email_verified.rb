class AddDefaultValueToEmailVerified < ActiveRecord::Migration
  def change
  	Member.update_all({email_confirmed: true})
  end
end
