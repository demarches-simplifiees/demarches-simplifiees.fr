class EmailCheckerController < ApplicationController
  def show
    render json: EmailChecker.new.check(email: params[:email])
  end
end
