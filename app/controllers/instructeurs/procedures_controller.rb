module Instructeurs
  class ProceduresController < InstructeurController
    before_action :ensure_ownership!, except: [:index]
    before_action :ensure_not_super_admin!, only: [:download_export]

    ITEMS_PER_PAGE = 25

    def index
      @procedures = current_instructeur
        .procedures
        .kept
        .with_attached_logo
        .includes(:defaut_groupe_instructeur)
        .order(closed_at: :desc, unpublished_at: :desc, published_at: :desc, created_at: :desc)

      dossiers = current_instructeur.dossiers
        .joins(groupe_instructeur: :procedure)
        .where(procedures: { hidden_at: nil })
      dossiers_visibles = dossiers.visible_by_administration
      @dossiers_count_per_procedure = dossiers_visibles.all_state.group('groupe_instructeurs.procedure_id').reorder(nil).count
      @dossiers_a_suivre_count_per_procedure = dossiers_visibles.without_followers.en_cours.group('groupe_instructeurs.procedure_id').reorder(nil).count
      @dossiers_archived_count_per_procedure = dossiers_visibles.archived.group('groupe_instructeurs.procedure_id').count
      @dossiers_termines_count_per_procedure = dossiers_visibles.termine.group('groupe_instructeurs.procedure_id').reorder(nil).count
      @dossiers_expirant_count_per_procedure = dossiers_visibles.termine_or_en_construction_close_to_expiration.group('groupe_instructeurs.procedure_id').count
      @dossiers_supprimes_recemment_count_per_procedure = dossiers.hidden_by_administration.group('groupe_instructeurs.procedure_id').reorder(nil).count

      groupe_ids = current_instructeur.groupe_instructeurs.pluck(:id)
      @followed_dossiers_count_per_procedure = current_instructeur
        .followed_dossiers
        .joins(:groupe_instructeur)
        .en_cours
        .where(groupe_instructeur_id: groupe_ids)
        .visible_by_administration
        .group('groupe_instructeurs.procedure_id')
        .reorder(nil)
        .count

      @all_dossiers_counts = {
        t('.to_follow') => @dossiers_a_suivre_count_per_procedure.sum { |_, v| v },
        t('.followed') => @followed_dossiers_count_per_procedure.sum { |_, v| v },
        t('.processed') => @dossiers_termines_count_per_procedure.sum { |_, v| v },
        t('.all') => @dossiers_count_per_procedure.sum { |_, v| v },
        t('.dossiers_close_to_expiration') => @dossiers_expirant_count_per_procedure.sum { |_, v| v },
        t('.archived') => @dossiers_archived_count_per_procedure.sum { |_, v| v },
        t('.dossiers_supprimes_recemment') => @dossiers_supprimes_recemment_count_per_procedure.sum { |_, v| v }
      }

      @procedure_ids_en_cours_with_notifications = current_instructeur.procedure_ids_with_notifications(:en_cours)
      @procedure_ids_termines_with_notifications = current_instructeur.procedure_ids_with_notifications(:termine)
    end

    def show
      @procedure = procedure
      # Technically, procedure_presentation already sets the attribute.
      # Setting it here to make clear that it is used by the view
      @procedure_presentation = procedure_presentation

      @current_filters = current_filters
      @displayable_fields_for_select, @displayable_fields_selected = procedure_presentation.displayable_fields_for_select
      @filterable_fields_for_select = procedure_presentation.filterable_fields_options
      @counts = current_instructeur
        .dossiers_count_summary(groupe_instructeur_ids)
        .symbolize_keys
      @can_download_dossiers = (@counts[:tous] + @counts[:archives]) > 0 && !instructeur_as_manager?

      dossiers = Dossier.where(groupe_instructeur_id: groupe_instructeur_ids)
      dossiers_count = @counts[statut.underscore.to_sym]

      @followed_dossiers_id = current_instructeur
        .followed_dossiers
        .en_cours
        .merge(dossiers.visible_by_administration)
        .pluck(:id)

      notifications = current_instructeur.notifications_for_groupe_instructeurs(groupe_instructeur_ids)
      @has_en_cours_notifications = notifications[:en_cours].present?
      @has_termine_notifications = notifications[:termines].present?
      @not_archived_notifications_dossier_ids = notifications[:en_cours] + notifications[:termines]

      filtered_sorted_ids = procedure_presentation.filtered_sorted_ids(dossiers, statut, count: dossiers_count)

      page = params[:page].presence || 1

      @dossiers_count = filtered_sorted_ids.size
      @filtered_sorted_paginated_ids = Kaminari
        .paginate_array(filtered_sorted_ids)
        .page(page)
        .per(ITEMS_PER_PAGE)

      @projected_dossiers = DossierProjectionService.project(@filtered_sorted_paginated_ids, procedure_presentation.displayed_fields)

      assign_exports
    end

    def deleted_dossiers
      @procedure = procedure
      @deleted_dossiers = @procedure
        .deleted_dossiers
        .order(:dossier_id)
        .page params[:page]

      @a_suivre_count, @suivis_count, @traites_count, @tous_count, @archives_count, @supprimes_recemment_count, @expirant_count = current_instructeur
        .dossiers_count_summary(groupe_instructeur_ids)
        .fetch_values('a_suivre', 'suivis', 'traites', 'tous', 'archives', 'supprimes_recemment', 'expirant')
      @can_download_dossiers = (@tous_count + @archives_count) > 0 && !instructeur_as_manager?

      notifications = current_instructeur.notifications_for_groupe_instructeurs(groupe_instructeur_ids)
      @has_en_cours_notifications = notifications[:en_cours].present?
      @has_termine_notifications = notifications[:termines].present?

      @statut = 'supprime'

      assign_exports
    end

    def update_displayed_fields
      values = params['values'].presence || [].to_json
      procedure_presentation.update_displayed_fields(JSON.parse(values))

      redirect_back(fallback_location: instructeur_procedure_url(procedure))
    end

    def update_sort
      procedure_presentation.update_sort(params[:table], params[:column])

      redirect_back(fallback_location: instructeur_procedure_url(procedure))
    end

    def add_filter
      respond_to do |format|
        format.html do
          procedure_presentation.add_filter(statut, params[:field], params[:value])

          redirect_back(fallback_location: instructeur_procedure_url(procedure))
        end
        format.turbo_stream do
          @statut = statut
          @procedure = procedure
          @procedure_presentation = procedure_presentation
          @field = params[:field]
        end
      end
    end

    def remove_filter
      procedure_presentation.remove_filter(statut, params[:field], params[:value])

      redirect_back(fallback_location: instructeur_procedure_url(procedure))
    end

    def download_export
      groupe_instructeurs = current_instructeur
        .groupe_instructeurs
        .where(procedure: procedure)

      @can_download_dossiers = current_instructeur
        .dossiers
        .visible_by_administration
        .exists?(groupe_instructeur_id: groupe_instructeur_ids) && !instructeur_as_manager?

      export = Export.find_or_create_export(export_format, groupe_instructeurs, **export_options)

      if export.available? && export.old? && force_export?
        export.destroy
        export = Export.find_or_create_export(export_format, groupe_instructeurs, **export_options)
      end

      if export.available?
        respond_to do |format|
          format.turbo_stream do
            @procedure = procedure
            @statut = export_options[:statut]
            @dossiers_count = export.count
            assign_exports
            flash.notice = "L’export au format \"#{export_format}\" est prêt. Vous pouvez le <a href=\"#{export.file.service_url}\">télécharger</a>"
          end

          format.html do
            redirect_to export.file.service_url
          end
        end
      else
        respond_to do |format|
          notice_message = "Nous générons cet export. Veuillez revenir dans quelques minutes pour le télécharger."

          format.turbo_stream do
            @procedure = procedure
            @statut = export_options[:statut]
            @dossiers_count = export.count
            assign_exports
            if !params[:no_progress_notification]
              flash.notice = notice_message
            end
          end

          format.html do
            redirect_to instructeur_procedure_url(procedure), notice: notice_message
          end
        end
      end
    end

    def email_notifications
      @procedure = procedure
      @assign_to = assign_tos.first
    end

    def update_email_notifications
      assign_tos.each do |assign_to|
        assign_to.update!(assign_to_params)
      end
      flash.notice = 'Vos notifications sont enregistrées.'
      redirect_to instructeur_procedure_path(procedure)
    end

    def stats
      @procedure = procedure
      @usual_traitement_time = @procedure.stats_usual_traitement_time
      @dossiers_funnel = @procedure.stats_dossiers_funnel
      @termines_states = @procedure.stats_termines_states
      @termines_by_week = @procedure.stats_termines_by_week
      @usual_traitement_time_by_month = @procedure.stats_usual_traitement_time_by_month_in_days
    end

    def email_usagers
      @procedure = procedure
      @commentaire = Commentaire.new
      @email_usagers_dossiers = email_usagers_dossiers
      @dossiers_count = @email_usagers_dossiers.count
      @groupe_instructeurs = email_usagers_groupe_instructeurs_label
      @bulk_messages = BulkMessage.includes(:groupe_instructeurs).where(groupe_instructeurs: { id: current_instructeur.groupe_instructeur_ids, procedure: procedure })
    end

    def create_multiple_commentaire
      @procedure = procedure
      errors = []

      email_usagers_dossiers.each do |dossier|
        commentaire = CommentaireService.build(current_instructeur, dossier, commentaire_params)
        if commentaire.save
          commentaire.dossier.update!(last_commentaire_updated_at: Time.zone.now)
        else
          errors << dossier.id
        end
      end

      valid_dossiers_count = email_usagers_dossiers.count - errors.count
      create_bulk_message_mail(valid_dossiers_count, Dossier.states.fetch(:brouillon))

      if errors.empty?
        flash[:notice] = "Tous les messages ont été envoyés avec succès"
      else
        flash[:alert] = "Envoi terminé. Cependant #{errors.count} messages n'ont pas été envoyés"
      end
      redirect_to instructeur_procedure_path(@procedure)
    end

    private

    def create_bulk_message_mail(dossier_count, dossier_state)
      BulkMessage.create(
        dossier_count: dossier_count,
        dossier_state: dossier_state,
        body: commentaire_params[:body],
        sent_at: Time.zone.now,
        instructeur_id: current_instructeur.id,
        piece_jointe: commentaire_params[:piece_jointe],
        groupe_instructeurs: email_usagers_groupe_instructeurs
      )
    end

    def assign_to_params
      params.require(:assign_to)
        .permit(:instant_expert_avis_email_notifications_enabled, :instant_email_dossier_notifications_enabled, :instant_email_message_notifications_enabled, :daily_email_notifications_enabled, :weekly_email_notifications_enabled)
    end

    def assign_exports
      @exports = Export.find_for_groupe_instructeurs(groupe_instructeur_ids, procedure_presentation)
    end

    def assign_tos
      @assign_tos ||= current_instructeur
        .assign_to
        .joins(:groupe_instructeur)
        .where(groupe_instructeur: { procedure_id: procedure_id })
    end

    def groupe_instructeur_ids
      @groupe_instructeur_ids ||= assign_tos
        .map(&:groupe_instructeur_id)
    end

    def statut
      @statut ||= (params[:statut].presence || 'a-suivre')
    end

    def export_format
      @export_format ||= params[:export_format]
    end

    def force_export?
      @force_export ||= params[:force_export].present?
    end

    def export_options
      @export_options ||= {
        time_span_type: params[:time_span_type],
        statut: params[:statut],
        procedure_presentation: params[:statut].present? ? procedure_presentation : nil
      }.compact
    end

    def procedure_id
      params[:procedure_id]
    end

    def procedure
      Procedure
        .with_attached_logo
        .find(procedure_id)
    end

    def ensure_ownership!
      if !current_instructeur.procedures.include?(procedure)
        flash[:alert] = "Vous n’avez pas accès à cette démarche"
        redirect_to root_path
      end
    end

    def redirect_to_avis_if_needed
      if current_instructeur.procedures.count == 0 && current_instructeur.avis.count > 0
        redirect_to instructeur_all_avis_path
      end
    end

    def procedure_presentation
      @procedure_presentation ||= get_procedure_presentation
    end

    def get_procedure_presentation
      procedure_presentation, errors = current_instructeur.procedure_presentation_and_errors_for_procedure_id(procedure_id)
      if errors.present?
        flash[:alert] = "Votre affichage a dû être réinitialisé en raison du problème suivant : " + errors.full_messages.join(', ')
      end
      procedure_presentation
    end

    def current_filters
      @current_filters ||= procedure_presentation.filters[statut]
    end

    def email_usagers_dossiers
      procedure.dossiers.state_brouillon.where(groupe_instructeur: current_instructeur.groupe_instructeur_ids).includes(:groupe_instructeur)
    end

    def email_usagers_groupe_instructeurs_label
      email_usagers_dossiers.map(&:groupe_instructeur).uniq.map(&:label)
    end

    def email_usagers_groupe_instructeurs
      email_usagers_dossiers.map(&:groupe_instructeur).uniq
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, :piece_jointe)
    end
  end
end
