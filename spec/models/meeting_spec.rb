require 'spec_helper'

require 'spec_helper'
describe "meeting scheduling" do
  describe "members in exclusive groups" do
    before :each do
      groups = %w{A B C}
      groups.each_with_index do |g, i|
        FactoryGirl.create(:group, name: g)
        name = "Member_of_#{g}"
        FactoryGirl.create(:member, name: name, email: "#{name}@artsymail.com", group_ids: [i + 1])
      end
    end

    it "succeeds" do
      
    end
  end
end