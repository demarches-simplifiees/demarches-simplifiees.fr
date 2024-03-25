class GroupeGestionnaire::GroupeGestionnaireCommentaires::CommentaireComponent < ApplicationComponent
  include ApplicationHelper

  def initialize(commentaire:, connected_user:, is_gestionnaire: true)
    @commentaire = commentaire
    @connected_user = connected_user
    @is_gestionnaire = is_gestionnaire
  end

  private

  def commentaire_issuer
    if @commentaire.sent_by?(@connected_user)
      t('.you')
    else
      (@commentaire.gestionnaire || @commentaire.sender).email
    end
  end

  def commentaire_date
    is_current_year = (@commentaire.created_at.year == Time.zone.today.year)
    l(@commentaire.created_at, format: is_current_year ? :message_date : :message_date_with_year)
  end
end
