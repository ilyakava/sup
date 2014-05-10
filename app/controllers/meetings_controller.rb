class MeetingsController < ApplicationController
  def edit
    @meeting = Meeting.find(params[:id])
    @member = Member.find(params[:member_id])
    @excluded_members = (@meeting.member_ids - params.fetch(:member_ids, []).map(&:to_i)).map { |id| Member.find(id) }
  end

  def update
    @meeting = Meeting.find(params[:id])
    @meeting.update_attribute(:member_ids, params[:member_ids])
    redirect_to root_path
  end
end
