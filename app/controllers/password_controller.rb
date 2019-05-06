require 'zxcvbn'

class PasswordController < ApplicationController
  include TrustedDeviceConcern

  def test
    @administrateur = Administrateur.new
    @administrateur.email = "toto@tutu.com"
    logger.debug("password controller")
  end

  def create
    flash.notice = "Mot de passe de force #{test_password_strength}"
    redirect_to password_path
  end

  def test_password_strength
    password = update_administrateur_params[:password]
    wxcvbn = Zxcvbn.test(password, [], ZXCVBN_DICTIONNARIES)
    @score = wxcvbn.score
    @length = password.present? ? password.length : 0
    @words = wxcvbn.match_sequence.map { |m| m.matched_word.nil? ? m.token : m.matched_word }.select { |s| s.length > 2 }.join(', ')
    # logger.debug("password controller: score=#{@score}, length=#{@length}, words=#{@words}")
  end

  private

  def update_administrateur_params
    params.require(:administrateur).permit(:reset_password_token, :password)
  end
end
