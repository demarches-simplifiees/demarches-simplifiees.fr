# frozen_string_literal: true

class ReleaseNotesController < ApplicationController
  before_action :ensure_access_allowed!
  after_action :touch_default_categories_seen_at

  def index
    @categories = params[:categories].presence || helpers.infer_default_announce_categories

    # Paginate per group of dates, then show all announces for theses dates
    @paginated_groups = ReleaseNote.published
      .for_categories(@categories)
      .select(:released_on)
      .group(:released_on)
      .order(released_on: :desc)
      .page(params[:page]).per(5)

    @announces = ReleaseNote.where(released_on: @paginated_groups.map(&:released_on))
      .with_rich_text_body
      .for_categories(@categories)
      .order(released_on: :desc, id: :asc)

    render "scrollable_list" if params[:page].present?
  end

  def nav_bar_profile = try_nav_bar_profile_from_referrer

  private

  def touch_default_categories_seen_at
    return if params[:categories].present? || params[:page].present?
    return if current_user.blank?

    return if current_user.announces_seen_at&.after?(@announces.max_by(&:released_on).released_on)

    current_user.touch(:announces_seen_at)
  end

  def ensure_access_allowed!
    return if administrateur_signed_in?
    return if instructeur_signed_in?
    return if expert_signed_in?

    flash[:alert] = t('release_notes.index.forbidden')
    redirect_to root_path
  end
end
