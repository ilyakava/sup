class Meeting < ActiveRecord::Base
  has_many :meeting_members, dependent: :destroy
  has_many :members, through: :meeting_members
  belongs_to :leader, class_name: 'Member'

  attr_accessible :member_ids, :meeting_date, :leader_id
  accepts_nested_attributes_for :members

  before_save :mark_members_not_left_out
  before_save :pick_meeting_date_if_none
  before_save :pick_leader_if_none

  # Conveniently instantiate many meetings
  def self.multiple_new_from_array(as)
    e = 'Input must be an array of arrays length 3 containing Member ids!'
    fail e unless (as.is_a? Array) && (as[0].is_a? Array) && (as[0][0].is_a? Numeric)
    as.map { |a| Meeting.new(member_ids: a) }
  end

  def self.trigger_weekly_email
    time_range = (3.days.ago..Time.now)
    Meeting.where(created_at: time_range).each do |meeting|
      MeetingMailer.new_meeting(meeting).deliver
    end
  end

  def self.trigger_followup_email
    time_range = (6.days.ago..Time.now)
    Meeting.where(meeting_date: time_range).each do |meeting|
      MeetingMailer.followup(meeting).deliver
    end
  end

  def mark_members_not_left_out
    members.each { |m| m.update_attribute(:left_out, false) }
  end

  def pick_leader_if_none
    self.leader = pick_leader unless leader
  end

  def pick_leader
    members.sample
  end

  # A method for regarding the meetup from a person's perspective
  # can be in either 1st or 3rd person. Supports referencing the
  # meeting as incomplete
  def ego_to_s(whoami, excluded_members = [], person = 1)
    pruned = members - excluded_members
    if excluded_members.count == 3
      person == 1 ? 'None of us' : 'No one'
    elsif pruned.count == 3
      person == 1 ? 'We all' : 'Everyone'
    # either none, all, or 1 person may be left out of a meeting
    elsif excluded_members.first == whoami
      pruned.map(&:to_s).join(' and ')
    else
      "#{(pruned - [whoami]).first} and #{person == 1 ? 'I' : 'you'}"
    end
  end

  # TODO: check calendars of members
  # Note that this method should run before the sunday that
  # the meeting should be scheduled for
  def self.choose_date(_member_ids = [])
    Date.parse('Monday') + 7.days + rand(5).days
  end

  def pick_meeting_date_if_none
    self.meeting_date = Meeting.choose_date unless meeting_date
  end

  # A cost function with two considerations:
  # 1) what is the time t since the members were in a meeting together last
  # 2) are the members a part of the same group
  def cost
    cost_from_shared_groups + cost_from_shared_meetings
  end

  def cost_from_shared_groups
    group_ids = members.map { |member| member.groups.pluck(:id) }
    # calculates the cost for this triplet by comparing pairs within this triplet

    group_ids.combination(2).reduce(0) do |acc, pairs_group_ids|
      pair_overlap = pairs_group_ids.first & pairs_group_ids.last
      cost_per_pair = pair_overlap.empty? ? 0 : pair_overlap.count * Cost::Helper::SHARED_GROUP
      acc + cost_per_pair
    end
  end

  def cost_from_shared_meetings
    meeting_ids = members.map { |member| member.meetings.pluck(:id) }
    # calculates the cost for this triplet by comparing pairs within this triplet
    meeting_ids.combination(2).reduce(0) do |acc, pairs_meeting_ids|
      pair_overlap = pairs_meeting_ids.first & pairs_meeting_ids.last
      cost_per_pair = pair_overlap.reduce(0) do |acc2, id|
        m = Meeting.find(id)
        weeks_ago = ((Time.now - m.meeting_date.to_time) / 1.week).floor
        cost_per_meeting = Cost::Helper.shared_meeting_n_weeks_ago(weeks_ago)
        acc2 + cost_per_meeting
      end
      acc + cost_per_pair
    end
  end

  def self.schedule_all
    # Convergence is much quicker when there is at least 1 left over member
    max_target_num_meetings = (Member.active.count - 1) / 3
    best_meetings = nil
    max_target_num_meetings.downto(1) do |target_num_meetings|
      best_meetings = Meeting.find_best_meeting(target_num_meetings)
      break unless best_meetings.nil?
    end
    Meeting.multiple_new_from_array(best_meetings).each { |m| m.save! }
  end

  # cost minimization strategy, monte carlo style
  def self.find_best_meeting(target_num_meetings)
    cursor = Cost::TripletGroupGenerator.new.enumerator(target_num_meetings)
    curr_best_meeting_round = nil
    curr_best_cost = Float::INFINITY
    trials_since_best_cost_beaten = 0

    cursor.each do |meeting_round|
      # disqualify meeting rounds with people belonging to several simultaneous
      # meetings this condition is not met the majority of times, so no need
      # to increment trials_since_best_cost_beaten
      exit =
        if meeting_round.flatten.uniq.length == (target_num_meetings * 3)
          cum_cost = Meeting.multiple_new_from_array(meeting_round).reduce(0) { |a, e| a + e.cost.to_f }
          # check if this meeting is the best so far
          if curr_best_cost > cum_cost
            curr_best_cost = cum_cost
            curr_best_meeting_round = meeting_round
            trials_since_best_cost_beaten = 0
          else
            trials_since_best_cost_beaten += 1
          end
          cum_cost # cumulative cost of 0 for meetings is optimal (the best solution possible)
        else
          1 # failure exit code (this value is not significant)
        end
      # conditions for a successful meeting being found
      break if exit.zero? || (trials_since_best_cost_beaten > 10 && !curr_best_meeting_round.nil?)
    end
    curr_best_meeting_round
  end
end
#--
# generated by 'annotated-rails' gem, please do not remove this line and content below, instead use `bundle exec annotate-rails -d` command
#++
# Table name: meetings
#
# * id           :integer         not null
#   meeting_date :date
#   created_at   :datetime
#   updated_at   :datetime
#   leader_id    :integer
#--
# generated by 'annotated-rails' gem, please do not remove this line and content above, instead use `bundle exec annotate-rails -d` command
#++
