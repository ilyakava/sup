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

  describe "a complicated real world example with multigroup memberships" do
    before :each do
      group_ids = (1..17).to_a.map { |n| Group.create(name: n.to_s).id }
      members_w_group_membership_indexes = [[7], [10], [16, 17, 9, 10, 15], [4, 15], [11], [12], [4, 16], [1], [5], [4, 16], [2], [1], [9, 11, 12, 13, 14], [4], [5], [4, 17], [16], [2], [4, 15], [5], [14], [4], [9, 10], [11], [4], [2], [11], [4], [9, 15, 16], [13], [4], [14], [13], [4, 15], [14], [13], [4], [12], [2], [4], [6], [17], [2], [1], [3], [10], [7], [3], [6], [5], [1]]
      members_w_group_membership_indexes.each do |ids|
        Member.create(
          name: rand(9999999999),
          email: "#{rand(9999999999)}@artsymail.com",
          group_ids: ids.map { |idx| group_ids[idx - 1]}
        )
      end
    end
    # bunched together tests here because these may take as long as a couple minutes each
    it "creates a permissible number of meetings through several rounds", :speed => 'slow' do
      10.times do |i|
        Timecop.travel(Date.today + (i * 1.week)) do
          start_time = Time.now
          Meeting.schedule_all
          expect(Meeting.count > 10).to be_true
          puts "made #{Meeting.count} meetings on round #{i}, taking #{Time.now - start_time} seconds"
        end
      end
    end
  end

  describe "a second complicated real world example with multigroup memberships" do
    before :each do
      group_ids = (1..17).to_a.map { |n| Group.create(name: n.to_s).id }
      members_w_group_membership_indexes = [[13, 14], [12], [13], [3], [11], [6], [12], [4, 16], [1], [5], [4, 16], [2], [1], [9, 11, 12, 13, 14], [4], [5], [4, 17], [16], [2], [4, 15], [5], [14], [4], [9, 10], [11], [4], [11], [4], [9, 15, 16], [13], [14], [13], [14], [13], [12], [2], [6], [17], [2], [1], [10], [7], [6, 15, 17], [4, 15, 16, 17], [2], [4], [4, 15], [4], [4], [10], [1], [3], [7], [5]]
      members_w_group_membership_indexes.each do |ids|
        Member.create(
          name: rand(9999999999),
          email: "#{rand(9999999999)}@artsymail.com",
          group_ids: ids.map { |idx| group_ids[idx - 1]}
        )
      end
    end
    # bunched together tests here because these may take as long as a couple minutes each
    it "creates a permissible number of meetings through several rounds", :speed => 'slow' do
      20.times do |i|
        Timecop.travel(Date.today + (i * 1.week)) do
          start_time = Time.now
          Meeting.schedule_all
          expect(Meeting.count > 10).to be_true
          puts "made #{Meeting.count} meetings on round #{i}, taking #{Time.now - start_time} seconds"
        end
      end
    end
  end
end

describe "Meeting::choose_date" do
  it "always returns a date" do
    expect(Meeting.choose_date([1,2,3]).is_a? Date).to be_true
  end
  it "chooses a date for the upcoming week" do
    # time the cron runs for scheduling the meetings
    friday = Date.parse('2014-05-09')
    monday = Date.parse('2014-05-12')
    next_friday = Date.parse('2014-05-16')
    Timecop.travel(friday.to_time + 14.hours + 30.minutes) do
      date = Meeting.choose_date([1,2,3])
      date.should be <= next_friday
      date.should be >= monday
    end
  end
end

describe "#leader" do
  before :each do
    groups = %w{A B C}
    distributions = [1, 1, 1]
    make_groups_and_members!(groups, distributions)
    @member_ids = Member.all.pluck(:id)
  end
  it "always returns the same leader" do
    m = Meeting.create(member_ids: @member_ids)
    ml1 = m.leader
    m.leader.should eq(ml1)
  end
end
