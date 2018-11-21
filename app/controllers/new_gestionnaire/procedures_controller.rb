module NewGestionnaire
  class ProceduresController < GestionnaireController
    before_action :ensure_ownership!, except: [:index]
    before_action :redirect_to_avis_if_needed, only: [:index]

    ITEMS_PER_PAGE = 25

    def index
      @procedures = current_gestionnaire.visible_procedures.order(archived_at: :desc, published_at: :desc)

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
    end

    def show
      @procedure = procedure

      @current_filters = current_filters
      @available_fields_to_filters = available_fields_to_filters
      # Technically, procedure_presentation already sets the attribute.
      # Setting it here to make clear that it is used by the view
      @procedure_presentation = procedure_presentation
      @displayed_fields_values = displayed_fields_values

      @a_suivre_dossiers = procedure
        .dossiers
        .includes(:user)
        .without_followers
        .en_cours

      @followed_dossiers = current_gestionnaire
        .followed_dossiers
        .includes(:user)
        .where(procedure: @procedure)
        .en_cours

      @followed_dossiers_id = current_gestionnaire
        .followed_dossiers
        .where(procedure: @procedure)
        .pluck(:id)

      @termines_dossiers = procedure.dossiers.includes(:user).termine

      @all_state_dossiers = procedure.dossiers.includes(:user).all_state

      @archived_dossiers = procedure.dossiers.includes(:user).archived

      @dossiers = case statut
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

      sorted_ids = procedure_presentation.sorted_ids(@dossiers, current_gestionnaire)

      if @current_filters.count > 0
        filtered_ids = procedure_presentation.filtered_ids(@dossiers, statut)
        filtered_sorted_ids = sorted_ids.select { |id| filtered_ids.include?(id) }
      else
        filtered_sorted_ids = sorted_ids
      end

      page = params[:page].presence || 1

      filtered_sorted_paginated_ids = Kaminari
        .paginate_array(filtered_sorted_ids)
        .page(page)
        .per(ITEMS_PER_PAGE)

      @dossiers = @dossiers.where(id: filtered_sorted_paginated_ids)

      eager_load_displayed_fields

      @dossiers = @dossiers.sort_by { |d| filtered_sorted_paginated_ids.index(d.id) }

      kaminarize(page, filtered_sorted_ids.count)
    end

    def update_displayed_fields
      values = params[:values]

      if values.nil?
        values = []
      end

      fields = values.map do |value|
        table, column = value.split("/")

        procedure_presentation.fields.find do |field|
          field['table'] == table && field['column'] == column
        end
      end

      procedure_presentation.update(displayed_fields: fields)

      current_sort = procedure_presentation.sort
      if !values.include?("#{current_sort['table']}/#{current_sort['column']}")
        procedure_presentation.update(sort: Procedure.default_sort)
      end

      redirect_back(fallback_location: gestionnaire_procedure_url(procedure))
    end

    def update_sort
      current_sort = procedure_presentation.sort
      table = params[:table]
      column = params[:column]

      if table == current_sort['table'] && column == current_sort['column']
        order = current_sort['order'] == 'asc' ? 'desc' : 'asc'
      else
        order = 'asc'
      end

      sort = {
        'table' => table,
        'column' => column,
        'order' => order
      }

      procedure_presentation.update(sort: sort)

      redirect_back(fallback_location: gestionnaire_procedure_url(procedure))
    end

    def add_filter
      if params[:value].present?
        filters = procedure_presentation.filters
        table, column = params[:field].split('/')
        label = procedure_presentation.fields.find { |c| c['table'] == table && c['column'] == column }['label']

        filters[statut] << {
          'label' => label,
          'table' => table,
          'column' => column,
          'value' => params[:value]
        }

        procedure_presentation.update(filters: filters)
      end

      redirect_back(fallback_location: gestionnaire_procedure_url(procedure))
    end

    def remove_filter
      filters = procedure_presentation.filters
      filter_to_remove = current_filters.find do |filter|
        filter['table'] == params[:table] && filter['column'] == params[:column]
      end

      filters[statut] = filters[statut] - [filter_to_remove]

      procedure_presentation.update(filters: filters)

      redirect_back(fallback_location: gestionnaire_procedure_url(procedure))
    end

    def download_dossiers
      options = params.permit(:limit, :since, tables: [])

      respond_to do |format|
        format.csv do
          send_data(procedure.to_csv(options),
            filename: procedure.export_filename(:csv))
        end
        format.xlsx do
          send_data(procedure.to_xlsx(options),
            filename: procedure.export_filename(:xlsx))
        end
        format.ods do
          send_data(procedure.to_ods(options),
            filename: procedure.export_filename(:ods))
        end
      end
    end

    private

    def statut
      @statut ||= (params[:statut].presence || 'a-suivre')
    end

    def procedure
      Procedure.find(params[:procedure_id])
    end

    def ensure_ownership!
      if !procedure.gestionnaires.include?(current_gestionnaire)
        flash[:alert] = "Vous n'avez pas accès à cette démarche"
        redirect_to root_path
      end
    end

    def redirect_to_avis_if_needed
      if current_gestionnaire.visible_procedures.count == 0 && current_gestionnaire.avis.count > 0
        redirect_to gestionnaire_avis_index_path
      end
    end

    def procedure_presentation
      @procedure_presentation ||= get_procedure_presentation
    end

    def get_procedure_presentation
      procedure_presentation, errors = current_gestionnaire.procedure_presentation_and_errors_for_procedure_id(params[:procedure_id])
      if errors.present?
        flash[:alert] = "Votre affichage a dû être réinitialisé en raison du problème suivant : " + errors.full_messages.join(', ')
      end
      procedure_presentation
    end

    def displayed_fields_values
      procedure_presentation.displayed_fields.map do |field|
        "#{field['table']}/#{field['column']}"
      end
    end

    def current_filters
      @current_filters ||= procedure_presentation.filters[statut]
    end

    def available_fields_to_filters
      current_filters_fields_ids = current_filters.map do |field|
        "#{field['table']}/#{field['column']}"
      end

      procedure_presentation.fields_for_select.reject do |field|
        current_filters_fields_ids.include?(field[1])
      end
    end

    def eager_load_displayed_fields
      procedure_presentation.displayed_fields
        .reject { |field| field['table'] == 'self' }
        .group_by do |field|
          if ['type_de_champ', 'type_de_champ_private'].include?(field['table'])
            'type_de_champ_group'
          else
            field['table']
          end
        end.each do |group_key, fields|
          case group_key
          when 'type_de_champ_group'
            if fields.any? { |field| field['table'] == 'type_de_champ' }
              @dossiers = @dossiers.includes(:champs).references(:champs)
            end

            if fields.any? { |field| field['table'] == 'type_de_champ_private' }
              @dossiers = @dossiers.includes(:champs_private).references(:champs_private)
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

    def kaminarize(current_page, total)
      @dossiers.instance_eval <<-EVAL
        def current_page
          #{current_page}
        end
        def total_pages
          (#{total} / #{ITEMS_PER_PAGE}.to_f).ceil
        end
        def limit_value
          #{ITEMS_PER_PAGE}
        end
        def first_page?
          current_page == 1
        end
        def last_page?
          current_page == total_pages
        end
      EVAL
    end
  end
end
