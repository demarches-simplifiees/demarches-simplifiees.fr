class LegalNoticeController < ApplicationController
invisible_captcha only: [:create], on_spam: :redirect_to_root

  def index

  end

end
