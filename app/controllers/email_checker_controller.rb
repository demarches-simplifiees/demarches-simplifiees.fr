class EmailCheckerController < ApplicationController
  def show
    render json: EmailChecker.check(email: params[:email])
  end
end
