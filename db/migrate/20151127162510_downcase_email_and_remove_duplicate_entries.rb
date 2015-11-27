class DowncaseEmailAndRemoveDuplicateEntries < ActiveRecord::Migration
  def change
  	members = Member.all
  	emails = []
  	members.each do |member|
  		member.email.downcase!
  		if emails.include?(member.email)
  			member.destroy
  		else
  			emails<<member.email
  			member.save!
  		end
  	end
  end
end
