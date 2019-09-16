module Instructeurs
  class ProceduresController < InstructeurController
    before_action :ensure_ownership!, except: [:index]
    before_action :redirect_to_avis_if_needed, only: [:index]

    ITEMS_PER_PAGE = 25

    def index
      @procedures = current_instructeur
        .visible_procedures
        .includes(:logo_attachment, :logo_active_storage_attachment, :defaut_groupe_instructeur)
        .order(archived_at: :desc, published_at: :desc, created_at: :desc)

      groupe_instructeurs = current_instructeur.groupe_instructeurs.where(procedure: @procedures)

      dossiers = current_instructeur.dossiers
      @dossiers_count_per_groupe_instructeur = dossiers.all_state.group(:groupe_instructeur_id).reorder(nil).count
      @dossiers_a_suivre_count_per_groupe_instructeur = dossiers.without_followers.en_cours.group(:groupe_instructeur_id).reorder(nil).count
      @dossiers_archived_count_per_groupe_instructeur = dossiers.archived.group(:groupe_instructeur_id).count
      @dossiers_termines_count_per_groupe_instructeur = dossiers.termine.group(:groupe_instructeur_id).reorder(nil).count

      @followed_dossiers_count_per_groupe_instructeur = current_instructeur
        .followed_dossiers
        .en_cours
        .where(groupe_instructeur: groupe_instructeurs)
        .group(:groupe_instructeur_id)
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
        .defaut_groupe_instructeur
        .dossiers
        .includes(:user)
        .without_followers
        .en_cours

      @followed_dossiers = current_instructeur
        .followed_dossiers
        .includes(:user)
        .where(groupe_instructeur: procedure.defaut_groupe_instructeur)
        .en_cours

      @followed_dossiers_id = current_instructeur
        .followed_dossiers
        .where(groupe_instructeur: procedure.defaut_groupe_instructeur)
        .pluck(:id)

      @termines_dossiers = procedure.defaut_groupe_instructeur.dossiers.includes(:user).termine

      @all_state_dossiers = procedure.defaut_groupe_instructeur.dossiers.includes(:user).all_state

      @archived_dossiers = procedure.defaut_groupe_instructeur.dossiers.includes(:user).archived

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

      sorted_ids = procedure_presentation.sorted_ids(@dossiers, current_instructeur)

      if @current_filters.count > 0
        filtered_ids = procedure_presentation.filtered_ids(@dossiers, statut)
        filtered_sorted_ids = sorted_ids.filter { |id| filtered_ids.include?(id) }
      else
        filtered_sorted_ids = sorted_ids
      end

      page = params[:page].presence || 1

      filtered_sorted_paginated_ids = Kaminari
        .paginate_array(filtered_sorted_ids)
        .page(page)
        .per(ITEMS_PER_PAGE)

      @dossiers = @dossiers.where(id: filtered_sorted_paginated_ids)

      @dossiers = procedure_presentation.eager_load_displayed_fields(@dossiers)

      @dossiers = @dossiers.sort_by { |d| filtered_sorted_paginated_ids.index(d.id) }

      kaminarize(page, filtered_sorted_ids.count)
    end

    def update_displayed_fields
      values = params[:values]

      if values.nil?
        values = []
      end

      fields = values.map do |value|
        find_field(*value.split('/'))
      end

      procedure_presentation.update(displayed_fields: fields)

      current_sort = procedure_presentation.sort
      if !values.include?(field_id(current_sort))
        procedure_presentation.update(sort: Procedure.default_sort)
      end

      redirect_back(fallback_location: instructeur_procedure_url(procedure))
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

      redirect_back(fallback_location: instructeur_procedure_url(procedure))
    end

    def add_filter
      if params[:value].present?
        filters = procedure_presentation.filters
        table, column = params[:field].split('/')
        label = find_field(table, column)['label']

        filters[statut] << {
          'label' => label,
          'table' => table,
          'column' => column,
          'value' => params[:value]
        }

        procedure_presentation.update(filters: filters)
      end

      redirect_back(fallback_location: instructeur_procedure_url(procedure))
    end

    def remove_filter
      filters = procedure_presentation.filters

      to_remove = params.values_at(:table, :column, :value)
      filters[statut].reject! { |filter| filter.values_at('table', 'column', 'value') == to_remove }

      procedure_presentation.update(filters: filters)

      redirect_back(fallback_location: instructeur_procedure_url(procedure))
    end

    def download_dossiers
      options = params.permit(:version, :limit, :since, tables: [])

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

    def email_notifications
      @procedure = procedure
      @assign_to = assign_to
    end

    def update_email_notifications
      assign_to.update!(email_notifications_enabled: params[:assign_to][:email_notifications_enabled])

      flash.notice = 'Vos notifications sont enregistrées.'
      redirect_to instructeur_procedure_path(procedure)
    end

    private

    def find_field(table, column)
      procedure_presentation.fields.find { |c| c['table'] == table && c['column'] == column }
    end

    def field_id(field)
      field.values_at('table', 'column').join('/')
    end

    def assign_to
      current_instructeur.assign_to.joins(:groupe_instructeur).find_by(groupe_instructeurs: { procedure: procedure })
    end

    def statut
      @statut ||= (params[:statut].presence || 'a-suivre')
    end

    def procedure
      Procedure.find(params[:procedure_id])
    end

    def ensure_ownership!
      if !procedure.defaut_groupe_instructeur.instructeurs.include?(current_instructeur)
        flash[:alert] = "Vous n'avez pas accès à cette démarche"
        redirect_to root_path
      end
    end

    def redirect_to_avis_if_needed
      if current_instructeur.visible_procedures.count == 0 && current_instructeur.avis.count > 0
        redirect_to instructeur_avis_index_path
      end
    end

    def procedure_presentation
      @procedure_presentation ||= get_procedure_presentation
    end

    def get_procedure_presentation
      procedure_presentation, errors = current_instructeur.procedure_presentation_and_errors_for_procedure_id(params[:procedure_id])
      if errors.present?
        flash[:alert] = "Votre affichage a dû être réinitialisé en raison du problème suivant : " + errors.full_messages.join(', ')
      end
      procedure_presentation
    end

    def displayed_fields_values
      procedure_presentation.displayed_fields.map { |field| field_id(field) }
    end

    def current_filters
      @current_filters ||= procedure_presentation.filters[statut]
    end

    def available_fields_to_filters
      procedure_presentation.fields_for_select
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
