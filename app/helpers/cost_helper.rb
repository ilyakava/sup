module CostHelper

  SHARED_GROUP = Float::INFINITY

  def shared_meeting_n_weeks_ago(n)
    case n
    when 0
      Float::INFINITY
    else
      (1.0 / n)**2.0
    end
  end
end
