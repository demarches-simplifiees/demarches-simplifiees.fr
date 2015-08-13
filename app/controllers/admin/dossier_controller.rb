class Admin::DossierController < ApplicationController
  before_action :authenticate_user!

  def show
    @dossier = Dossier.find(params[:dossier_id])
    @entreprise = @dossier.entreprise.decorate
    @etablissement = @dossier.etablissement
    @pieces_jointes = @dossier.pieces_jointes
    @commentaires = @dossier.commentaires.order(created_at: :desc)
    @commentaires = @commentaires.all.decorate
    @commentaire_email = current_user.email

    @formulaire = @dossier.ref_formulaire
    @liste_pieces_jointes = RefPiecesJointe.get_liste_piece_jointe @dossier.ref_formulaire
    @array_id_pj_valides = PieceJointe.get_array_id_pj_valid_for_dossier @dossier.id
    @dossier = @dossier.decorate
  rescue ActiveRecord::RecordNotFound
    redirect_start
  end

  def index
    @dossier = Dossier.find(params[:dossier_id])
    redirect_to url_for({controller: 'admin/dossier', action: :show, :dossier_id => @dossier.id})
  rescue
    redirect_start
  end

  private

  def redirect_start
    redirect_to url_for({controller: '/start', action: :error_dossier})
  end
end
