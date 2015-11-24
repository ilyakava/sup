module Cost
  SHARED_GROUP = Float::INFINITY

  # This class's primary purpose is to check many meeting costs efficiently in
  # memory to avoid hitting the slow db repeatedly.
  # This class also contains some helper methods used in the triplet tree
  # exploration class, TripletGroupGenerator
  class TripletFactory
    def initialize
      @groups_to_members = Hash[Group.all.map do |g|
        [g.id, g.members.pluck(:id)]
      end]
      @members_to_groups = Hash[Member.active.map do |m|
        [m.id, m.groups.pluck(:id)]
      end]
      @members_to_last_week_meeting_members = Hash[Member.active.map do |m|
        meeting_ids = m.meetings.map do |meeting|
          weeks_ago = ((Time.now - meeting.meeting_date.to_time) / 1.week).floor
          meeting.id if weeks_ago <= 4 # pretty strict
        end
        [m.id, meeting_ids.compact]
      end]
    end

    def triplets_to_num_restrictions
      v = valid_triplets_unsorted
      Hash[v.map { |trip| [trip, trip.map { |m_id| @members_to_groups[m_id] + @members_to_last_week_meeting_members[m_id] }.flatten.uniq.length] }]
    end

    def valid_triplets_unsorted
      Member.active.pluck(:id).combination(3).to_a.select do |trip|
        cost_is_finite(trip)
      end
    end

    def valid_triplets
      v = valid_triplets_unsorted
      v.sort_by { |trip| trip.map { |m_id| @members_to_groups[m_id] }.flatten.length }
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
        acc + cost_per_pair
      end
    end

    def trip_cost_from_shared_meetings_is_finite(trip)
      meeting_ids = trip.map { |member_id| @members_to_last_week_meeting_members[member_id] }
      # A recent meeting is treated just as strictly as a group membership
      TripletFactory.cost_from_shared_groups(meeting_ids) < Float::INFINITY
    end
  end

  # This class is for keeping values to score individual meetings by
  class Helper
    SHARED_GROUP = Float::INFINITY

    # Returns the cost for a shared meeting in the past
    def self.shared_meeting_n_weeks_ago(n)
      case n
      when 0
        Float::INFINITY
      else
        (1.0 / n)**2.0
      end
    end
  end

  # This class is for enumerating over groups of triplets in a less stupid way
  # than using the combination Array method, which will result in many more
  # infinitely costly triples or impossible triples (with members in multiple
  # meetings in 1 week) than not
  class TripletGroupGenerator
    # NUM_SEEDS is the number of groups to break deep branches into
    # this number was chosen from trial and error, looking at
    # completion times for the complicated pairing setup in the specs.
    # Initialy this number was used to rotate through the deepest branches
    # in the tree of possible triplet groups, but this was unneccessary.
    # It is still performant to use this seed to only yield 1/20th of the
    # branches that the depth first search enumerates.
    NUM_SEEDS = 20

    def initialize
      @tf = TripletFactory.new
      @all_triplets = @tf.valid_triplets
      all_triplets_flat = @all_triplets.flatten
      @member_ids = Member.active.pluck(:id)
      # This is a hash where for every key (a member id) the value is an array
      # of indexes in @all_triplets where the member id does not occur.
      @member_id_to_non_membered_triplet_indexes = Hash[
        @member_ids.map do |id|
          allowed_indexes = []
          res = all_triplets_flat.each_with_index.map { |e, i| e == id ? nil : (i / 3) }
          until res.empty?
            take = res.pop(3)
            allowed_indexes << take.first if take.none?(&:nil?)
          end
          [id, allowed_indexes.uniq]
        end
      ]
      self
    end

    def enumerator(target_num_triplets)
      Enumerator.new do |output|
        best_triplets_to_start(target_num_triplets).each do |trip|
          level(target_num_triplets, output, 0, [trip])
        end
      end
    end

    private

    # member_ids with the most restrictions appear in the least number
    # of spots in @member_id_to_non_membered_triplet_indexes, and thereby
    # have the greatest number of allowable other triplets to appear with
    def best_triplets_to_start(_target_num_triplets)
      ttnr = @tf.triplets_to_num_restrictions
      m = ttnr.values.max
      # an easy way to find the few hundred triplets that have the most
      # allowances (since array intersection is quite slow)
      counter = 0
      hardest2pair_triplets = {}
      until hardest2pair_triplets.count > 50 || hardest2pair_triplets.count == ttnr.count
        hardest2pair_triplets = Hash[ttnr.select { |_k, v| v >= (m - counter) }]
        counter += 1
      end
      # map member choices to the number of additional choices for triplets that they have
      hardest2pair_to_num_allowances = Hash[hardest2pair_triplets.keys.map do |members|
        h = @member_id_to_non_membered_triplet_indexes
        idxs = members.map { |id| h[id] }
        [members, Performant::Array.memory_efficient_intersect(idxs).length]
      end]
      hardest2pair_to_num_allowances.keys.sort_by { |k| -hardest2pair_to_num_allowances[k] }
    end

    # depth first search for valid triplet groupings
    def level(target_num_triplets, yielder, seed, arr_of_trips)
      if arr_of_trips.length == target_num_triplets
        print '.'
        yielder << arr_of_trips # The final case is a side-effect
      else
        # pick another triplet for the group that does not contain any member_ids
        # that are already in the current group of triplets. This is ensured by
        # intersecting the arrays of allowed indexes in the hash h, with some memoization
        h = @member_id_to_non_membered_triplet_indexes
        members = arr_of_trips.flatten.sort
        valid_addition_indexes =
          if h[(key = members.to_s)].nil?
            idxs = members.map { |id| h[id] }
            h[key] = Performant::Array.memory_efficient_intersect(idxs)
          else
            h[key]
          end
        # Only use 1/NUM_SEEDS of the deepest branches unless we have nearly collected enough triplets
        valid_addition_indexes_subset =
          if (target_num_triplets - arr_of_trips.length) > 2
            which_vai_to_explore_now = (1...valid_addition_indexes.length).to_a.select { |idx| idx % NUM_SEEDS == seed }
            which_vai_to_explore_now.map { |idx| valid_addition_indexes[idx] }
          end
        next_indexes = valid_addition_indexes_subset || valid_addition_indexes
        next_indexes.each do |addition_index|
          trip = @all_triplets[addition_index]
          level(target_num_triplets, yielder, seed, [*arr_of_trips, trip])
        end
      end
    end
  end
end
