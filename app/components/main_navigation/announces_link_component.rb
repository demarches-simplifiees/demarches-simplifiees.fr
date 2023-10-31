# frozen_string_literal: true

class MainNavigation::AnnouncesLinkComponent < ApplicationComponent
  def render?
    # also see app/controllers/release_notes_controller.rb#ensure_access_allowed!
    return false if !helpers.instructeur_signed_in? && !helpers.administrateur_signed_in? && !helpers.expert_signed_in?

    @most_recent_released_on = load_most_recent_released_on

    @most_recent_released_on.present?
  end

  def something_new?
    return true if current_user.announces_seen_at.nil?

    @most_recent_released_on.after? current_user.announces_seen_at
  end

  def load_most_recent_released_on
    categories = helpers.infer_default_announce_categories

    ReleaseNote.most_recent_announce_date_for_categories(categories)
  end
end
