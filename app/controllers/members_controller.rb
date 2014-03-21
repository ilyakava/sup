class MembersController < ApplicationController
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
        MemberMailer.welcome_email(@member).deliver

        format.html { redirect_to(root_path, notice: 'Member was successfully created.') }
        format.json { render json: @member, status: :created, location: @member }
      else
        format.html { render action: 'new' }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @member = Member.find(params[:id])
  end

  def update
    @member = Member.find(params[:id])
    @member.update_attributes(params[:member])
    redirect_to root_path
  end

  def destroy
    @member = Member.find(params[:id])
    @member.destroy!
    redirect_to root_path
  end

  private

  def member_params
    params.require(:member).permit!
  end
end
