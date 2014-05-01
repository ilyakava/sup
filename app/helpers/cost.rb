require 'set'

module Cost
  class Helper

    SHARED_GROUP = Float::INFINITY
    def self.all_triplets
      Member.all.pluck(:id).shuffle.combination(3).to_a
    end

    def initialize
      all_triplets_flat = Helper.all_triplets.flatten
      # should be a hash where for every key (a member id) the value is an array
      # of indexes in Helper.all_triplets where the member id does not occur
      # Then take the intersection of these values
      @member_id_to_non_membered_triplet_indexes = Hash[
        Member.all.map do |member|
          id = member.id
          forbidden_ids = [id, *member.groups.map { |g| g.members.pluck(:id) }.flatten].uniq
          allowed_indexes = []
          res = all_triplets_flat.each_with_index.map { |e,i| forbidden_ids.include?(e) ? nil : (i / 3) }
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
      # starting the set should be arbitrary
      set_of_arr_of_trips = Set.new([[Helper.all_triplets.first]])
      until set_of_arr_of_trips.first.length == target_num_triplets
        set_of_arr_of_trips = add_one_more_trip_to_set(set_of_arr_of_trips)
      end

      Enumerator.new do |o|
        set_of_arr_of_trips.each do |arr_of_trips|
          o << arr_of_trips
        end
      end
    end



    def add_one_more_trip_to_set(set_of_arr_of_trips)
      puts "add_one_more_trip_to_set with #{set_of_arr_of_trips.first.length}"
      new_set = Set.new
      h = @member_id_to_non_membered_triplet_indexes
      set_of_arr_of_trips.each do |arr_of_trips|
        member_ids_so_far = arr_of_trips.flatten
        # get the allowed indexes for each member_id, and take the intersection
        allowed_triplet_indexes = member_ids_so_far.map { |id| h[id] }.inject(&:&)
        # binding.pry if allowed_triplet_indexes == false
        puts "iterating on #{allowed_triplet_indexes.length}"
        allowed_triplet_indexes.each do |idx|
          new_set << [Helper.all_triplets[idx], *arr_of_trips]
        end
      end
      new_set
    end
  end
end
