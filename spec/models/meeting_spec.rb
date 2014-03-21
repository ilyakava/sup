require 'spec_helper'

def make_groups_and_members!(groups, distributions)
  groups.each do |g|
    FactoryGirl.create(:group, name: g)
  end
  groups.length.times do |idx|
    distributions[idx].times do |mi|
      name = "Member_#{mi + 1}_of_#{groups[idx]}"
      FactoryGirl.create(:member, name: name, email: "#{name}@artsymail.com", group_ids: [idx + 1])
    end
  end
end

describe "overall meeting scheduling" do
  describe "members in exclusive groups" do
    before :each do
      groups = %w{A B C}
      distributions = [1, 1, 1]
      make_groups_and_members!(groups, distributions)
    end

    it "succeeds" do
      Meeting.schedule_all
      expect(Meeting.first.members).to eq(Member.all)
      expect(Meeting.count).to eq(1)
    end
  end
  describe "a perfectly symmetrical example" do
    before :each do
      groups = %w{A B C}
      distributions = [3, 3, 3]
      make_groups_and_members!(groups, distributions)
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

  describe "a very symmetrical example" do
    before :each do
      groups = %w{A B C D}
      distributions = [2, 2, 1, 1]
      make_groups_and_members!(groups, distributions)
    end

    it "creates the right number of meetings" do
      Meeting.schedule_all
      expect(Meeting.count).to eq(2)
    end

    it "doesn't pair those in the same work group" do
      Meeting.schedule_all
      Meeting.all.each do |meeting|
        expect(meeting.members.map(&:groups).flatten.uniq.count).to eq(3)
      end
    end
  end

  describe "a simple example with 3 leftovers" do
    before :each do
      groups = %w{A B C}
      distributions = [3, 2, 1]
      make_groups_and_members!(groups, distributions)
    end

    it "creates the right number of meetings" do
      Meeting.schedule_all
      expect(Meeting.count).to eq(1)
    end

    it "doesn't pair those in the same work group" do
      Meeting.schedule_all
      Meeting.all.each do |meeting|
        expect(meeting.members.map(&:groups).flatten.uniq.count).to eq(3)
      end
    end
  end

  describe "a simple example with 1 leftover" do
    before :each do
      groups = %w{A B C D E}
      distributions = [1, 2, 2, 1, 1]
      make_groups_and_members!(groups, distributions)
    end

    it "creates the right number of meetings" do
      Meeting.schedule_all
      expect(Meeting.count).to eq(2)
    end

    it "doesn't pair those in the same work group" do
      Meeting.schedule_all
      Meeting.all.each do |meeting|
        expect(meeting.members.map(&:groups).flatten.uniq.count).to eq(3)
      end
    end
  end
end

describe "Meeting::choose_date" do
  it "always returns a date" do
    expect(Meeting.choose_date([1,2,3]).is_a? Date).to be_true
  end
end