class Admin::ProceduresController < ApplicationController
  before_action :authenticate_administrateur!

  def index
    @procedures = Procedure.all
  end

  def show
    @procedure = Procedure.find(params[:id])
    @types_de_champ = @procedure.types_de_champ.order(:order_place)
    @types_de_piece_justificative = @procedure.types_de_piece_justificative.order(:libelle)

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end

  def new
    @procedure ||= Procedure.new
  end

  def create
    @procedure = Procedure.new(create_procedure_params)

    unless @procedure.save
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'new'
    end

    process_new_types_de_champ_params
    process_new_types_de_piece_justificative_params

    flash.notice = 'Procédure enregistrée'
    redirect_to admin_procedures_path
  end

  def update
    # raise
    @procedure = Procedure.find(params[:id])

    unless @procedure.update_attributes(create_procedure_params)
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end

    process_new_types_de_champ_params
    process_update_types_de_champ_params

    process_new_types_de_piece_justificative_params
    process_update_types_de_piece_justificative_params

    flash.notice = 'Préocédure modifiée'
    redirect_to admin_procedures_path
  end

  private

  def process_new_types_de_champ_params
    unless params[:procedure][:new_type_de_champ].nil?
      params[:procedure][:new_type_de_champ].each do |new_type_de_champ|
        type_de_champ = TypeDeChamp.new

        if new_type_de_champ[1]['_destroy'] == 'false'
          save_new_type_de_champ type_de_champ, new_type_de_champ[1]
        end
      end
    end
  end

  def process_update_types_de_champ_params
    unless params[:procedure][:types_de_champ].nil?
      params[:procedure][:types_de_champ].each do |type_de_champ|
        tmp = TypeDeChamp.find(type_de_champ[0])
        if type_de_champ[1]['_destroy'] == 'false'
          save_new_type_de_champ tmp, type_de_champ[1]

        elsif type_de_champ[1]['_destroy'] == 'true'
          tmp.destroy
        end
      end
    end
  end

  def process_new_types_de_piece_justificative_params
    unless params[:procedure][:new_type_de_piece_justificative].nil?
      params[:procedure][:new_type_de_piece_justificative].each do |new_type_de_piece_justificative|
        type_de_pj = TypeDePieceJustificative.new

        if new_type_de_piece_justificative[1]['_destroy'] == 'false'
          save_new_type_de_piece_justificative type_de_pj, new_type_de_piece_justificative[1]
        end
      end
    end
  end


  def process_update_types_de_piece_justificative_params
    unless params[:procedure][:types_de_piece_justificative].nil?
      params[:procedure][:types_de_piece_justificative].each do |type_de_piece_justificative|
        tmp = TypeDePieceJustificative.find(type_de_piece_justificative[0])

        if type_de_piece_justificative[1]['_destroy'] == 'false'
          save_new_type_de_piece_justificative tmp, type_de_piece_justificative[1]

        elsif type_de_piece_justificative[1]['_destroy'] == 'true'
          tmp.destroy
        end
      end
    end
  end



  def save_new_type_de_champ database_object, source
    database_object.libelle = source[:libelle]
    database_object.type_champs = source[:type_champs]
    database_object.description = source[:description]
    database_object.order_place = source[:order_place]
    database_object.procedure = @procedure

    database_object.save
  end

  def save_new_type_de_piece_justificative database_object, source
    database_object.libelle = source[:libelle]
    database_object.description = source[:description]
    database_object.procedure = @procedure

    database_object.save
  end

  def create_procedure_params
    params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :use_api_carto)

    #params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :use_api_carto, types_de_champ_attributes: [:libelle, :description, :order_place, :type_champs])
  end
end
