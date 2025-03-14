# frozen_string_literal: true

class ReleaseNotesController < ApplicationController
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

  private

  def touch_default_categories_seen_at
    return if params[:categories].present? || params[:page].present?
    return if current_user.blank?

    return if current_user.announces_seen_at&.after?(@announces.max_by(&:released_on).released_on)

    current_user.touch(:announces_seen_at)
  end
end
