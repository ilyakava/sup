class FeedbacksController < ApplicationController
  def create
    @meeting = Feedback.create(params)
    redirect_to root_path
  end
end
