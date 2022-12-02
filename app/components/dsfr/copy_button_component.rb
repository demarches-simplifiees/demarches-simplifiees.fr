class Dsfr::CopyButtonComponent < ApplicationComponent
  def initialize(text:, title:, success: nil)
    @text = text
    @title = title
    @success = success
  end
end
