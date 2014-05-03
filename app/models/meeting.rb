class Meeting < ActiveRecord::Base

  has_many :meeting_members, dependent: :destroy
  has_many :members, through: :meeting_members

  attr_accessible :member_ids, :meeting_date
  accepts_nested_attributes_for :members

  before_save :mark_members_not_left_out
  before_save :pick_meeting_date_if_none

  def mark_members_not_left_out
    members.each { |m| m.update_attribute(:left_out, false) }
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

    # Cost::SharedGroup.cost_from_shared_groups(group_ids)

    group_ids.combination(2).reduce(0) do |acc, pairs_group_ids|
      pair_overlap = pairs_group_ids.first & pairs_group_ids.last
      cost_per_pair = pair_overlap.empty? ? 0 : pair_overlap.count * Cost::Helper::SHARED_GROUP
      acc += cost_per_pair
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
        acc2 += cost_per_meeting
      end
      acc += cost_per_pair
    end
  end

  def self.schedule_all
    max_target_num_meetings = Member.count / 3
    best_meetings = nil
    max_target_num_meetings.downto(1) do |target_num_meetings|
      best_meetings = Meeting.find_best_meeting(target_num_meetings)
      break unless best_meetings.nil?
    end
    Meeting.multiple_new_from_array(best_meetings).each { |m| m.save! }
  end

  # cost minimization strategy, monte carlo style
  def self.find_best_meeting(target_num_meetings)
    cursor = Cost::Helper.new.enumerator(target_num_meetings)
    curr_best_meeting_round = nil
    curr_best_cost = Float::INFINITY
    trials_since_best_cost_beaten = 0
    crap_counter = 0

    cursor.each do |meeting_round|
      # disqualify meeting rounds with people belonging to several simultaneous
      # meetings this condition is not met the majority of times, so no need
      # to increment trials_since_best_cost_beaten
      exit = if meeting_round.flatten.uniq.length == (target_num_meetings * 3)
        puts "doing it #{crap_counter += 1}, with cost #{curr_best_cost}"
        cum_cost = Meeting.multiple_new_from_array(meeting_round).reduce(0) { |a, e| a += e.cost.to_f }
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
        1 # traditional failure exit code (this value is not significant)
      end
      # conditions for a successful meeting being found
      break if exit.zero? || (trials_since_best_cost_beaten > 50 && !curr_best_meeting_round.nil?)
    end
    curr_best_meeting_round
  end

  def self.multiple_new_from_array(as)
    e = "Input must be an array of arrays length 3 containing Member ids!"
    raise e unless (as.is_a? Array) && (as[0].is_a? Array) && (as[0][0].is_a? Numeric)
    as.map { |a| Meeting.new(member_ids: a) }
  end


  # put everyone in a group, draw connections as edges
  # rank by edges
  # pick first by rank
  # pick second by rank that isn't connected to first
  # pick third by rank that isn't connected to either first or second
  def self.schedule_all2
    exit_flag = false # talk about laziness
    ranks = Hash[Member.all.map do |member|
      edge_ids = member.edge_ids
      advantage = member.left_out ? 100 : 0
      [member.id, {edges: edge_ids, num_edges: edge_ids.count + advantage}]
    end]

    until ranks.empty?
      meeting_member_ids = []
      forbidden_member_ids = []
      until meeting_member_ids.length == 3
        pair = self.delete_max_rank(forbidden_member_ids, ranks, meeting_member_ids.length)
        if pair.nil?
          # at this point it is impossible to create any more triplets
          exit_flag = true
          # meeting_member_ids will be partially populated at this point
          [*ranks.keys, *meeting_member_ids].each { |member_id| Member.find(member_id).update_attribute(:left_out, true) }
        end
        break if exit_flag
        meeting_member_ids << pair.first
        forbidden_member_ids.concat(pair.last[:edges])
      end
      break if exit_flag
      Meeting.create(member_ids: meeting_member_ids, meeting_date: self.choose_date(meeting_member_ids))
    end
  end

  def self.trigger_weekly_email
    time_range = (3.days.ago..Time.now)
    Meeting.where(created_at: time_range).each do |meeting|
      MeetingMailer.new_meeting(meeting).deliver
    end
  end

  def self.trigger_weekly_debug_email
    time_range = (3.days.ago..Time.now)
    Meeting.where(created_at: time_range).each do |meeting|
      MeetingMailer.new_meeting_debug(meeting).deliver
    end
  end

  # TODO check calendars of members
  def self.choose_date(member_ids = [])
    nearest_monday = Date.commercial(Date.today.year, 1+Date.today.cweek, 1)
    return nearest_monday + rand(5).days
  end

  def pick_meeting_date_if_none
    self.meeting_date = Meeting.choose_date unless meeting_date
  end

  # mutates ranks!
  # we want to delete the max rank while also preventing the
  # future restricted ids from becoming everyone in sup
  def self.delete_max_rank(restricted_ids_arr, rem_ranks, num_paired)
    rem_ranks_copy = rem_ranks.dup
    restricted_ids_arr.each { |r_id| rem_ranks_copy.delete(r_id) }

    if rem_ranks_copy.empty?
      # if this happens then there are no more valid triplets in the rem_ranks
      nil
    else
      p_id, p_h = rem_ranks_copy.max_by do |id, h|
        if restricted_ids_arr.include?(id)
          -Float::INFINITY
        elsif (((Member.count - 5)..(Member.count)).to_a.include?((h[:edges] + restricted_ids_arr).uniq.length))
          # collectively, the restricted ids should not account
          # for everyone if this is the 2nd person in the triplet
          -Float::INFINITY
        else
          h[:num_edges]
        end
      end
      rem_ranks.delete(p_id)
      [p_id, p_h]
    end
  end

  # its not really predictable how the groups of 3 will be devided, so this is
  # a random enough yet consistent way of selecting a "leader" for each meeting
  def leader
    members.last
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
#--
# generated by 'annotated-rails' gem, please do not remove this line and content above, instead use `bundle exec annotate-rails -d` command
#++
