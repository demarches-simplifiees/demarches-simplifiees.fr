class Procedure::InvitationWithTypoComponent < ApplicationComponent
  def initialize(maybe_typo:, url:, title:)
    @maybe_typo = maybe_typo
    @url = url
    @title = title
  end

  def render?
    @maybe_typo.present?
  end
end
