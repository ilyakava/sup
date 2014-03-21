require 'spec_helper'

require 'spec_helper'
describe "overall meeting scheduling" do
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
      Meeting.schedule_all
      expect(Meeting.first.members).to eq(Member.all)
      expect(Meeting.count).to eq(1)
    end
  end
  describe "a symmetrical example" do
    before :each do
      groups = %w{A B C}
      groups.each_with_index do |g, i|
        FactoryGirl.create(:group, name: g)
        3.times do |mi|
          name = "Member_#{mi + 1}_of_#{g}"
          FactoryGirl.create(:member, name: name, email: "#{name}@artsymail.com", group_ids: [i + 1])
        end
      end
    end

    it "creates the right number of meetings" do
      Meeting.schedule_all
      expect(Meeting.count).to eq(3)
    end

    it "doesn't pair those in the same work group" do
      Meeting.schedule_all
      Meeting.all.each do |meeting|
        expect(meeting.members.map(&:groups).flatten.uniq.count).to eq(3)
      end
    end
  end
end

# describe "" do
# end