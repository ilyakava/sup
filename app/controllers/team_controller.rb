class TeamController < ApplicationController
  def index
    @groups = Group.all.includes(:members)
  end
end
