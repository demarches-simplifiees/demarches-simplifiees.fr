class RecoveriesController < ApplicationController
  def nature
  end

  def post_nature
    if nature_params == 'collectivite'
      redirect_to identification_recovery_path
    else
      redirect_to support_recovery_path(error: :other_nature)
    end
  end

  def identification
  end

  def post_identification
    redirect_to selection_recovery_path
  end

  def selection
  end

  def post_selection
    redirect_to terminee_recovery_path
  end

  def terminee
  end

  def support
  end

  private

  def nature_params = params[:nature]
end
