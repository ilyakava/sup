class TeamController < ApplicationController
  def index
    @groups = Group.includes(:members)
  end
end
