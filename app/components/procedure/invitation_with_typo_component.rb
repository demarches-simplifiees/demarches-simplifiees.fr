class Procedure::InvitationWithTypoComponent < ApplicationComponent
  def initialize(maybe_typos:, url:, title:)
    @maybe_typos = maybe_typos
    @url = url
    @title = title
  end

  def render?
    @maybe_typos.present?
  end
end
