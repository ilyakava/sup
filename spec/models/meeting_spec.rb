require 'spec_helper'

def make_groups_and_members!(groups, distributions)
  groups.each do |g|
    Group.create(name: g)
  end
  Group.all.to_a.each_with_index do |group, idx|
    distributions[idx].times do |mi|
      name = "Member_#{mi + 1}_of_#{group.name}"
      Member.create(name: name, email: "#{name}@artsymail.com", group_ids: [group.id])
    end
  end
end

describe "the cost of an individual meeting" do
  describe '#cost_from_shared_groups' do
    it "calculates the right cost for a meeting of group members" do
      groups = %w{A}
      distributions = [3]
      make_groups_and_members!(groups, distributions)
      group_member_ids = Group.first.members.pluck(:id)
      invalid_meeting = Meeting.new(member_ids: group_member_ids)
      invalid_meeting.cost_from_shared_groups.should eq(Float::INFINITY)
    end

    it "calculates the right cost for a meeting of exclusive group members" do
      groups = %w{A B C}
      distributions = [1, 1, 1]
      make_groups_and_members!(groups, distributions)
      member_ids = Member.all.pluck(:id)
      meeting = Meeting.new(member_ids: member_ids)
      meeting.cost_from_shared_groups.should eq(0)
    end
  end

  describe '#cost_from_shared_meetings' do
    describe "the cost of the same meeting across different time spans" do
      before :each do
        groups = %w{A B C}
        distributions = [1, 1, 1]
        make_groups_and_members!(groups, distributions)
        @member_ids = Member.all.pluck(:id)
      end

      it "calculates the right cost for a repeated meeting in the same week" do
        Meeting.create(member_ids: @member_ids, meeting_date: Date.yesterday)
        invalid_meeting = Meeting.new(member_ids: @member_ids)
        invalid_meeting.cost_from_shared_meetings.should eq(Float::INFINITY)
      end

      it "calculates a lower cost for a meeting repeated later" do
        m = Meeting.create(member_ids: @member_ids)
        costs = []
        5.times do |i|
          m.update_attributes(meeting_date: Date.today - (2 + i).weeks)
          costs << Meeting.new(member_ids: @member_ids).cost_from_shared_meetings
        end
        costs.uniq.length.should_not eq(1)
        until costs.empty?
          costs.min.should eq(costs.pop)
        end
      end
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
      pending("scheduling changes in progress")
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