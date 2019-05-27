require 'zxcvbn'

class PasswordMockController < ApplicationController
  include TrustedDeviceConcern

  def new
    credential = params[:credential]
    credential ||= 'usager'
    case credential
    when 'user', 'usager'
      @credential = User.new
    when 'administrateur', 'admin'
      @credential = Administrateur.new
    when 'instructeur', 'gestionnaire'
      @credential = Gestionnaire.new
    else
      @credential = User.new
      flash.notice = 'credential parameter must be one of (usager,instructeur,administrateur)'
    end
    @credential.email = "#{credential}@gov.pf"
  end

  def create
    compute_strength
    if params[:administrateur].present?
      credential = 'administrateur'
    elsif params[:gestionnaire].present?
      credential = 'instructeur'
    else
      credential = 'usager'
    end
    flash.notice = "Mot de passe de force #{@score} #{credential}"
    redirect_to password_mock_path(credential: credential)
  end

  def test_strength
    compute_strength
    render 'shared/password/test_strength'
  end

  private

  def compute_strength
    if params[:administrateur].present?
      password = params[:administrateur][:password]
      @min_complexity = PASSWORD_COMPLEXITY_FOR_ADMIN
    elsif params[:gestionnaire].present?
      password = params[:gestionnaire][:password]
      @min_complexity = PASSWORD_COMPLEXITY_FOR_GESTIONNAIRE
    elsif params[:user].present?
      password = params[:user][:password]
      @min_complexity = PASSWORD_COMPLEXITY_FOR_USER
    else
      password = ''
      @min_complexity = PASSWORD_COMPLEXITY_FOR_USER
    end
    @score, @words, @length = ZxcvbnService.new(password).complexity
    @min_length = PASSWORD_MIN_LENGTH
  end
end
