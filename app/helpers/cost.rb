require 'set'

module Cost
  SHARED_GROUP = Float::INFINITY

  # This class's primary purpose is to check many meeting costs efficiently
  # It does this in memory to avoid hitting the slow db repeatedly
  class TripletFactory
    def initialize
      @groups_to_members = Hash[Group.all.map do |g|
        [g.id, g.members.pluck(:id)]
      end]
      @members_to_groups = Hash[Member.all.map do |m|
        [m.id, m.groups.pluck(:id)]
      end]
      @members_to_last_week_meeting_members = Hash[Member.all.map do |m|
        meeting_ids = m.meetings.map do |meeting|
          weeks_ago = ((Time.now - meeting.meeting_date.to_time) / 1.week).floor
          meeting.id if weeks_ago <= 2
        end
        [m.id, meeting_ids.compact]
      end]
    end

    def valid_triplets
      valid = Member.all.pluck(:id).combination(3).to_a.select do |trip|
        cost_is_finite(trip)
      end
      valid.sort_by { |trip| trip.map { |m_id| @members_to_groups[m_id] }.flatten.length }
    end

    def cost_is_finite(trip)
      trip_cost_from_shared_groups(trip) < Float::INFINITY && trip_cost_from_shared_meetings_is_finite(trip)
    end

    def trip_cost_from_shared_groups(trip)
      group_ids = trip.map { |member_id| @members_to_groups[member_id] }
      TripletFactory.cost_from_shared_groups(group_ids)
    end

    def self.cost_from_shared_groups(group_ids)
      # calculates the cost for this triplet by comparing pairs within this triplet
      group_ids.combination(2).reduce(0) do |acc, pairs_group_ids|
        pair_overlap = pairs_group_ids.first & pairs_group_ids.last
        cost_per_pair = pair_overlap.empty? ? 0 : pair_overlap.count * Cost::SHARED_GROUP
        acc += cost_per_pair
      end
    end

    def trip_cost_from_shared_meetings_is_finite(trip)
      meeting_ids = trip.map { |member_id| @members_to_last_week_meeting_members[member_id] }
      TripletFactory.cost_from_shared_groups(meeting_ids) < Float::INFINITY
    end
  end

  class Helper
    SHARED_GROUP = Float::INFINITY
    # NUM_SEEDS is the number of groups to break deep branches into
    # this number was chosen from trial and error, looking at
    # completion times for the complicated pairing setup in the specs
    NUM_SEEDS = 20

    def initialize
      @all_triplets = TripletFactory.new.valid_triplets
      all_triplets_flat = @all_triplets.flatten
      # This is a hash where for every key (a member id) the value is an array
      # of indexes in @all_triplets where the member id does not occur
      # Then take the intersection of these values
      @member_id_to_non_membered_triplet_indexes = Hash[
        Member.all.map do |member|
          id = member.id
          allowed_indexes = []
          res = all_triplets_flat.each_with_index.map { |e,i| e == id ? nil : (i / 3) }
          until res.empty?
            take = res.pop(3)
            allowed_indexes << take.first if take.none? { |i| i.nil? }
          end
          [id, allowed_indexes.uniq]
        end
      ]
      self
    end

    def self.shared_meeting_n_weeks_ago(n)
      case n
      when 0
        Float::INFINITY
      else
        (1.0 / n)**2.0
      end
    end

    def enumerator(target_num_triplets)
      Enumerator.new do |output|
        (0...NUM_SEEDS).to_a.each do |seed|
          level(target_num_triplets, output, seed)
        end
      end
    end

    # depth first search for valid triplet groupings
    def level(target_num_triplets, yielder, seed, arr_of_trips = [])
      if arr_of_trips.length == target_num_triplets
        # The final case
        yielder << arr_of_trips
      else
        valid_addition_indexes = if arr_of_trips.empty?
          # The base case for valid_addition_indexes
          (0...(@all_triplets.length)).to_a
        else
          # remove all of tripliets containing members already selected by
          # intersecting the arrays of allowed indexes in the hash h
          h = @member_id_to_non_membered_triplet_indexes
          members = arr_of_trips.flatten.sort
          if h[(key = members.to_s)].nil?
            h[key] = members.map { |id| h[id] }.reduce(&:&)
          else
            h[key]
          end
        end
        # rotate through deepest branches unless we are near enough triplets
        valid_addition_indexes_subset = if (target_num_triplets - arr_of_trips.length) > 3
          which_VAI_to_explore_now = (1...valid_addition_indexes.length).to_a.select { |idx| idx % NUM_SEEDS == seed }
          which_VAI_to_explore_now.map { |idx| valid_addition_indexes[idx] }
        end
        next_indexes = valid_addition_indexes_subset || valid_addition_indexes
        if next_indexes.blank?
          return :bad_branch_one_level_deep # if there are no further choices
        else
          next_indexes.each do |addition_index|
            trip = @all_triplets[addition_index]
            value = level(target_num_triplets, yielder, seed, [*arr_of_trips, trip])
            return :bad_branch_two_levels_deep if value == :bad_branch_one_level_deep
            return if value == :bad_branch_two_levels_deep
          end
        end
      end
    end
  end
end
