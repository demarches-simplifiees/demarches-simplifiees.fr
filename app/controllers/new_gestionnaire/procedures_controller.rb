module NewGestionnaire
  class ProceduresController < GestionnaireController
    before_action :ensure_ownership!, except: [:index]
    before_action :redirect_to_avis_if_needed, only: [:index]

    def index
      @procedures = current_gestionnaire.procedures.order(archived_at: :desc, published_at: :desc)

      dossiers = current_gestionnaire.dossiers
      @dossiers_count_per_procedure = dossiers.all_state.group(:procedure_id).reorder(nil).count
      @dossiers_a_suivre_count_per_procedure = dossiers.without_followers.en_cours.group(:procedure_id).reorder(nil).count
      @dossiers_archived_count_per_procedure = dossiers.archived.group(:procedure_id).count
      @dossiers_termines_count_per_procedure = dossiers.termine.group(:procedure_id).reorder(nil).count

      @followed_dossiers_count_per_procedure = current_gestionnaire
        .followed_dossiers
        .en_cours
        .where(procedure: @procedures)
        .group(:procedure_id)
        .reorder(nil)
        .count

      @notifications_count_per_procedure = current_gestionnaire.notifications_count_per_procedure
    end

    def show
      @procedure = procedure

      @a_suivre_dossiers = procedure
        .dossiers
        .includes(:user)
        .without_followers
        .en_cours

      @followed_dossiers = current_gestionnaire
        .followed_dossiers
        .includes(:user, :notifications)
        .where(procedure: @procedure)
        .en_cours

      @followed_dossiers_id = current_gestionnaire
        .followed_dossiers
        .where(procedure: @procedure)
        .pluck(:id)

      @termines_dossiers = procedure.dossiers.includes(:user).termine

      @all_state_dossiers = procedure.dossiers.includes(:user).all_state

      @archived_dossiers = procedure.dossiers.includes(:user).archived

      @statut = params[:statut].present? ? params[:statut] : 'a-suivre'

      @dossiers = case @statut
      when 'a-suivre'
        @a_suivre_dossiers
      when 'suivis'
        @followed_dossiers
      when 'traites'
        @termines_dossiers
      when 'tous'
        @all_state_dossiers
      when 'archives'
        @archived_dossiers
      end

      @displayed_fields = procedure_presentation.displayed_fields
      @displayed_fields_values = displayed_fields_values
      eager_load_displayed_fields

      @dossiers = @dossiers.page([params[:page].to_i, 1].max)
    end

    def update_displayed_fields
      values = params[:values] || []
      fields = values.map do |value|
        table, column = value.split("/")

        c = procedure.fields.find do |field|
          field['table'] == table && field['column'] == column
        end

        c.to_json
      end

      procedure_presentation.update_attributes(displayed_fields: fields)

      redirect_back(fallback_location: procedure_url(procedure))
    end

    private

    def procedure
      Procedure.find(params[:procedure_id])
    end

    def ensure_ownership!
      if !procedure.gestionnaires.include?(current_gestionnaire)
        flash[:alert] = "Vous n'avez pas accès à cette procédure"
        redirect_to root_path
      end
    end

    def redirect_to_avis_if_needed
      if current_gestionnaire.procedures.count == 0 && current_gestionnaire.avis.count > 0
        redirect_to avis_index_path
      end
    end

    def procedure_presentation
      @procedure_presentation ||= current_gestionnaire.procedure_presentation_for_procedure_id(params[:procedure_id])
    end

    def displayed_fields_values
      procedure_presentation.displayed_fields.map do |field|
        "#{field['table']}/#{field['column']}"
      end
    end

    def eager_load_displayed_fields
      @displayed_fields
        .reject { |field| field['table'] == 'self' }
        .group_by do |field|
          if ['type_de_champ', 'type_de_champ_private'].include?(field['table'])
            'type_de_champ_group'
          else
            field['table']
          end
        end.each do |_, fields|

        case fields.first['table']
        when'france_connect_information'
          @dossiers = @dossiers.includes({ user: :france_connect_information })
        when 'type_de_champ', 'type_de_champ_private'
          if fields.any? { |field| field['table'] == 'type_de_champ' }
            @dossiers = @dossiers.includes(:champs)
          end

          if fields.any? { |field| field['table'] == 'type_de_champ_private' }
            @dossiers = @dossiers.includes(:champs_private)
          end

          where_conditions = fields.map do |field|
            "champs.type_de_champ_id = #{field['column']}"
          end.join(" OR ")

          @dossiers = @dossiers.where(where_conditions)
        else
          @dossiers = @dossiers.includes(fields.first['table'])
        end
      end
    end
  end
end
