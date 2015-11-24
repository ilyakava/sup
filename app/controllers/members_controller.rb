class MembersController < ApplicationController
  before_filter :fetch_member, :check_email_confirmed, only: [:edit, :update, :destroy]

  def index
    @members = Member.all
  end

  def new
    @member = Member.new
  end

  def create
    @member = Member.new(member_params)

    respond_to do |format|
      if @member.save
        # Tell the UserMailer to send a welcome Email after save
        MemberMailer.registration_confirmation(@member).deliver_now

        format.html { redirect_to(action: :index, notice: 'Member was successfully created. Please verify your email address.') }
        format.json { render json: @member, status: :created, location: @member }
      else
        format.html { render action: 'new' }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  def verify_email
    @member = Member.find_by_email_confirmation_token(params[:id])
    if @member
      @member.activate!
      MemberMailer.welcome_email(@member).deliver_now
      flash[:success] = "Welcome to the S'Up! Your email has been confirmed."
      redirect_to action: :index
    else
      flash[:error] = 'Invalid token'
      redirect_to action: :index
    end
  end

  def fetch_member
    @member = Member.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def not_found
    fail ActionController::RoutingError, 'Mr. Holmes has been notified about the missing member'
  end

  def edit
  end

  def update
    @member.update_attributes(params[:member])
    redirect_to action: :index
  end

  def destroy
    @member.destroy!
    redirect_to action: :index
  end

  def graph
    dict = {}
    edges = []
    node_data = []
    # create dict used by edge lines and write node lines
    Member.active.each_with_index do |member, i|
      switch_node_name = i
      dict[member.id] = switch_node_name
      node_data << { name: member.name }
    end

    # create edge lines
    Group.all.each do |group|
      pairwise_combos = group.members.active.pluck(:id).combination(2)
      pairwise_combos.each do |c|
        edges << [dict[c.first], dict[c.last]]
      end
    end
    @node_data_str = node_data.to_json.html_safe
    @link_data_str = edges.to_json.html_safe
  end

  def check_email_confirmed
    redirect_to action: :index unless @member.email_confirmed
  end

  private

  def member_params
    params.require(:member).permit!
  end
end
