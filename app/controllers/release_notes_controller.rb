class ReleaseNotesController < ApplicationController
  before_action :ensure_access_allowed!

  def index
    @categories = params[:categories].presence || infer_default_categories

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

  def infer_default_categories
    if administrateur_signed_in?
      ['administrateur', 'usager', current_administrateur.api_tokens.exists? ? 'api' : nil]
    elsif instructeur_signed_in?
      ['instructeur', 'expert']
    elsif expert_signed_in?
      ['expert']
    else
      ['usager']
    end
  end

  def ensure_access_allowed!
    return if administrateur_signed_in?
    return if instructeur_signed_in?
    return if expert_signed_in?

    flash[:alert] = t('release_notes.index.forbidden')
    redirect_to root_path
  end
end
