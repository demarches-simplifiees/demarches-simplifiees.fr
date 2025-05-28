module Instructeurs
  class DossiersController < ProceduresController
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TextHelper
    include CreateAvisConcern
    include DossierHelper
    include TurboChampsConcern

    include ActionController::Streaming
    include Zipline

    before_action :redirect_on_dossier_not_found, only: :show
    before_action :redirect_on_dossier_in_batch_operation, only: [:archive, :unarchive, :follow, :unfollow, :passer_en_instruction, :repasser_en_construction, :repasser_en_instruction, :terminer, :restore, :destroy, :extend_conservation]
    after_action :mark_demande_as_read, only: :show

    after_action :mark_messagerie_as_read, only: [:messagerie, :create_commentaire, :pending_correction]
    after_action :mark_avis_as_read, only: [:avis, :create_avis]
    after_action :mark_annotations_privees_as_read, only: [:annotations_privees, :update_annotations]

    def extend_conservation
      dossier.extend_conservation(1.month)
      flash[:notice] = t('views.instructeurs.dossiers.archived_dossier')
      redirect_back(fallback_location: instructeur_dossier_path(@dossier.procedure, @dossier))
    end

    def extend_conservation_and_restore
      dossier.extend_conservation_and_restore(1.month, current_instructeur)
      flash[:notice] = t('views.instructeurs.dossiers.archived_dossier')
      redirect_back(fallback_location: instructeur_dossier_path(@dossier.procedure, @dossier))
    end

    def geo_data
      send_data dossier.to_feature_collection.to_json,
                type: 'application/json',
                filename: "dossier-#{dossier.id}-features.json"
    end

    def apercu_attestation
      send_data dossier.attestation_template.send(:build_pdf, dossier),
                filename: 'attestation.pdf',
                type: 'application/pdf',
                disposition: 'inline'
    end

    def bilans_bdf
      extension = params[:format]
      render extension.to_sym => dossier.etablissement.entreprise_bilans_bdf_to_sheet(extension)
    end

    def show
      @demande_seen_at = current_instructeur.follows.find_by(dossier: dossier_with_champs)&.demande_seen_at
      @is_dossier_in_batch_operation = dossier.batch_operation.present?
      respond_to do |format|
        format.pdf do
          @acls = PiecesJustificativesService.new(user_profile: current_instructeur, export_template: nil).acl_for_dossier_export(dossier.procedure)
          render(template: 'dossiers/show', formats: [:pdf])
        end
        format.all
      end
    end

    def messagerie
      @commentaire = Commentaire.new
      @messagerie_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.messagerie_seen_at
    end

    def annotations_privees
      @annotations_privees_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.annotations_privees_seen_at
    end

    def avis
      @avis_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.avis_seen_at
      @avis = Avis.new
      @experts_emails = Expert.autocomplete_mails(@dossier.procedure)
    end

    def avis_new
      @avis_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.avis_seen_at
      @avis = Avis.new
      @experts_emails = Expert.autocomplete_mails(@dossier.procedure)
    end

    def personnes_impliquees
      # sort following_instructeurs (last follower on top) for the API of Agence de l'Eau Loire-Bretagne
      @following_instructeurs_emails = dossier.followers_instructeurs.joins(:follows).merge(Follow.order(id: :desc)).map(&:email)
      previous_followers = dossier.previous_followers_instructeurs - dossier.followers_instructeurs
      @previous_following_instructeurs_emails = previous_followers.map(&:email)
      @avis_emails = dossier.experts.map(&:email)
      @invites_emails = dossier.invites.map(&:email)
      @potential_recipients = dossier.groupe_instructeur.instructeurs.reject { |g| g == current_instructeur }
      @manual_assignments = dossier.dossier_assignments.manual.includes(:groupe_instructeur, :previous_groupe_instructeur)
    end

    def send_to_instructeurs
      recipients = params['recipients'].presence || []
      # instructeurs are scoped by groupe_instructeur to avoid enumeration
      recipients = dossier.groupe_instructeur.instructeurs.where(id: recipients)

      if recipients.present?
        recipients.each do |recipient|
          recipient.follow(dossier)
          InstructeurMailer.send_dossier(current_instructeur, dossier, recipient).deliver_later
        end
        flash.notice = "Dossier envoyé"
      else
        flash.alert = "Instructeur inconnu ou non présent sur la procédure"
      end

      redirect_to(personnes_impliquees_instructeur_dossier_path(procedure, dossier))
    end

    def follow
      current_instructeur.follow(dossier)
      flash.notice = 'Dossier suivi'
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def unfollow
      current_instructeur.unfollow(dossier)
      flash.notice = "Vous ne suivez plus le dossier nº #{dossier.id}"

      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def archive
      dossier.archiver!(current_instructeur)
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def unarchive
      dossier.desarchiver!
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def passer_en_instruction
      begin
        dossier.passer_en_instruction!(instructeur: current_instructeur)
        flash.notice = 'Dossier passé en instruction.'
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: :en_instruction)
      end

      @dossier = dossier
      respond_to do |format|
        format.turbo_stream do
          render :change_state
        end

        format.html do
          redirect_back(fallback_location: instructeur_procedure_path(procedure))
        end
      end
    end

    def repasser_en_construction
      begin
        dossier.repasser_en_construction!(instructeur: current_instructeur)
        flash.notice = 'Dossier repassé en construction.'
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: :en_construction)
      end

      @dossier = dossier
      respond_to do |format|
        format.turbo_stream do
          render :change_state
        end

        format.html do
          redirect_back(fallback_location: instructeur_procedure_path(procedure))
        end
      end
    end

    def repasser_en_instruction
      begin
        flash.notice = "Le dossier #{dossier.id} a été repassé en instruction."
        dossier.repasser_en_instruction!(instructeur: current_instructeur)
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: :en_instruction)
      end

      @dossier = dossier
      respond_to do |format|
        format.turbo_stream do
          render :change_state
        end

        format.html do
          redirect_back(fallback_location: instructeur_procedure_path(procedure))
        end
      end
    end

    def terminer
      motivation = params[:dossier] && params[:dossier][:motivation]
      justificatif = params[:dossier] && params[:dossier][:justificatif_motivation]

      h = { instructeur: current_instructeur, motivation: motivation, justificatif: justificatif }

      begin
        case params[:process_action]
        when "refuser"
          target_state = :refuse
          dossier.refuser!(h)
          flash.notice = "Dossier considéré comme refusé."
        when "classer_sans_suite"
          target_state = :sans_suite
          dossier.classer_sans_suite!(h)
          flash.notice = "Dossier considéré comme sans suite."
        when "accepter"
          target_state = :accepte
          dossier.accepter!(h)
          flash.notice = "Dossier traité avec succès."
        end
      rescue AASM::InvalidTransition => e
        flash.alert = aasm_error_message(e, target_state: target_state)
      end

      @dossier = dossier
      render :change_state
    end

    def pending_correction
      message, piece_jointe = params.require(:dossier).permit(:motivation, :justificatif_motivation).values

      if message.empty?
        flash.alert = "Vous devez préciser quelle correction est attendue."
      elsif !dossier.may_flag_as_pending_correction?
        flash.alert = dossier.termine? ? "Impossible de demander de corriger un dossier terminé." : "Le dossier est déjà en attente de correction."
      else
        commentaire = CommentaireService.build(current_instructeur, dossier, { body: message, piece_jointe: })

        if commentaire.valid?
          dossier.flag_as_pending_correction!(commentaire, params[:reason].presence)
          dossier.update!(last_commentaire_updated_at: Time.zone.now)
          current_instructeur.follow(dossier)

          flash.notice = "Dossier marqué comme en attente de correction."
        else
          flash.alert = commentaire.errors.full_messages.map { "Commentaire : #{_1}" }
        end
      end

      respond_to do |format|
        format.turbo_stream do
          @dossier = dossier
          render :change_state
        end

        format.html do
          redirect_back(fallback_location: instructeur_procedure_path(procedure))
        end
      end
    end

    def create_commentaire
      @commentaire = CommentaireService.create(current_instructeur, dossier, commentaire_params)

      if @commentaire.errors.empty?
        @commentaire.dossier.update!(last_commentaire_updated_at: Time.zone.now)
        current_instructeur.follow(dossier)
        flash.notice = "Message envoyé"
        redirect_to messagerie_instructeur_dossier_path(procedure, dossier)
      else
        @commentaire.piece_jointe.purge.reload
        flash.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def create_avis
      @avis = create_avis_from_params(dossier, current_instructeur)

      if @avis.nil?
        redirect_to avis_instructeur_dossier_path(procedure, dossier)
      else
        @avis_seen_at = current_instructeur.follows.find_by(dossier: dossier)&.avis_seen_at
        render :avis
      end
    end

    def update_annotations
      dossier_with_champs.update_champs_attributes(remove_changes_forbidden_by_visa, :private, updated_by: current_user.email)
      if dossier.champs.any?(&:changed_for_autosave?)
        dossier.last_champ_private_updated_at = Time.zone.now
      end

      dossier.save(context: :champs_private_value)
      dossier.index_search_terms_later

      ChampRevision.create_or_update_revision_if_needed(dossier, champs_private_attributes_params, current_instructeur.id)

      respond_to do |format|
        format.turbo_stream do
          @to_show, @to_hide, @to_update = champs_to_turbo_update(champs_private_attributes_params, dossier.champs.filter(&:private?))
        end
      end
    end

    def print
      @dossier = dossier
      render layout: "print"
    end

    def annotation
      @dossier = dossier_with_champs(pj_template: false)
      type_de_champ = @dossier.find_type_de_champ_by_stable_id(params[:stable_id], :private)
      annotation = @dossier.project_champ(type_de_champ, params[:row_id])

      respond_to do |format|
        format.turbo_stream do
          @to_show, @to_hide = []
          @to_update = [annotation]

          render :update_annotations
        end
      end
    end

    def telecharger_pjs
      files = ActiveStorage::DownloadableFile.create_list_from_dossiers(dossiers: Dossier.where(id: dossier.id), user_profile: current_instructeur)
      cleaned_files = ActiveStorage::DownloadableFile.cleanup_list_from_dossier(files)

      zipline(cleaned_files, "dossier-#{dossier.id}.zip")
    end

    def destroy
      if dossier.termine?
        dossier.hide_and_keep_track!(current_instructeur, :instructeur_request)
        flash.notice = t('instructeurs.dossiers.deleted_by_instructeur')
      else
        flash.alert = t('instructeurs.dossiers.impossible_deletion')
      end
      redirect_back(fallback_location: instructeur_procedure_path(procedure))
    end

    def restore
      dossier = current_instructeur.dossiers.find(params[:dossier_id])
      dossier.restore(current_instructeur)
      flash.notice = t('instructeurs.dossiers.restore')

      if dossier.termine?
        redirect_to instructeur_procedure_path(procedure, statut: :traites)
      else
        redirect_back(fallback_location: instructeur_procedure_path(procedure))
      end
    end

    def reaffectation
      @dossier = current_instructeur.dossiers.find(params[:dossier_id])

      @groupe_instructeur = @dossier.groupe_instructeur

      @groupes_instructeurs = Kaminari.paginate_array(@groupe_instructeur.other_groupe_instructeurs)
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
    end

    def reaffecter
      dossier = current_instructeur.dossiers.find(params[:dossier_id])

      new_group = dossier
        .procedure
        .groupe_instructeurs.find(params[:groupe_instructeur_id])

      dossier.assign_to_groupe_instructeur(new_group, DossierAssignment.modes.fetch(:manual), current_instructeur)

      flash.notice = t('instructeurs.dossiers.reaffectation', dossier_id: dossier.id, label: new_group.label)
      redirect_to instructeur_procedure_path(procedure)
    end

    def pieces_jointes
      @dossier = current_instructeur.dossiers.find(params[:dossier_id])

      champs_attachments_and_libelles = @dossier
        .champs
        .filter { _1.class.in?([Champs::PieceJustificativeChamp, Champs::TitreIdentiteChamp]) }
        .flat_map do |c|
          c.piece_justificative_file.map do |attachment|
            [attachment, c.libelle]
          end
        end

      commentaires_attachments_and_libelles = @dossier
        .commentaires
        .map(&:piece_jointe)
        .map(&:attachments)
        .flatten
        .map { [_1, 'Messagerie'] }

      @attachments_and_libelles = champs_attachments_and_libelles + commentaires_attachments_and_libelles
    end

    private

    def checked_visa?(c)
      c.type_champ == 'visa' && c.value.present?
    end

    def dossier_scope
      if action_name == 'update_annotations'
        Dossier
          .where(id: current_instructeur.dossiers.visible_by_administration)
          .or(Dossier.where(id: current_user.dossiers.for_procedure_preview))
      elsif action_name == 'extend_conservation_and_restore'
        Dossier
          .where(id: current_instructeur.dossiers.visible_by_administration)
          .or(Dossier.where(id: current_instructeur.dossiers.hidden_by_expired))
      else
        current_instructeur.dossiers.visible_by_administration
      end
    end

    def dossier
      @dossier ||= DossierPreloader.load_one(dossier_scope.find(params[:dossier_id])).tap do
        set_sentry_dossier(_1)
      end
    end

    def dossier_with_champs
      @dossier ||= DossierPreloader.load_one(dossier_scope.find(params[:dossier_id]))
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, piece_jointe: [])
    end

    def champs_private_params
      champ_attributes = [
        :id,
        :value,
        :value_other,
        :external_id,
        :code,
        :primary_value,
        :secondary_value,
        :numero_allocataire,
        :code_postal,
        :identifiant,
        :numero_fiscal,
        :reference_avis,
        :ine,
        :piece_justificative_file,
        :code_departement,
        :accreditation_number,
        :accreditation_birthdate,
        :lexpol,
        :feature,
        value: []
      ] + TypeDeChamp::INSTANCE_CHAMPS_PARAMS
      # Strong attributes do not support records (indexed hash); they only support hashes with
      # static keys. We create a static hash based on the available keys.
      public_ids = params.dig(:dossier, :champs_private_attributes)&.keys || []
      champs_private_attributes = public_ids.map { [_1, champ_attributes] }.to_h
      params.require(:dossier).permit(champs_private_attributes:)
    end

    def champs_private_attributes_params
      champs_private_params.fetch(:champs_private_attributes)
    end

    # Trie les champs privés d'un dossier selon l'ordre défini par la révision
    def ordered_private_champs(dossier_instance)
      rtdcs = dossier_instance.revision.revision_types_de_champ_private.includes(:type_de_champ, parent: {})

      # Créer des tables de recherche pour un accès plus rapide
      rtdc_by_stable_id = {}
      parent_positions = {}

      rtdcs.each do |rtdc|
        rtdc_by_stable_id[rtdc.type_de_champ.stable_id] = rtdc

        # Pré-calculer les positions des parents
        if rtdc.parent_id
          parent_positions[rtdc.id] = rtdcs.find { |r| r.id == rtdc.parent_id }&.position || 0
        end
      end

      # Ordonner les champs selon leur position dans la révision
      champs = dossier_instance.champs_private.to_a
      champs.sort_by! do |champ|
        rtdc = rtdc_by_stable_id[champ.stable_id]
        parent_position = rtdc&.parent_id ? parent_positions[rtdc.id] || 0 : 0
        [parent_position, champ.row_id || ' ', rtdc&.position || 0]
      end
    end

    # Vérifie si le dossier contient des champs de type visa validés
    def has_validated_visa?(dossier_instance)
      dossier_instance.champs_private
        .where(type: 'Champs::VisaChamp')
        .where.not(value: ["", nil])
        .exists?
    end

    def remove_changes_forbidden_by_visa
      return champs_private_attributes_params unless has_validated_visa?(dossier)

      # Récupérer les champs ordonnés
      ordered_champs = ordered_private_champs(dossier)

      params[:dossier][:champs_private_attributes]&.reject! do |k, _v|
        # Trouver le champ modifié
        champ_index = ordered_champs.index { |c| c.public_id == k }
        next unless champ_index

        # rechercher à la suite soit un visa soit un titre de sections de niveau 1
        champ = ordered_champs[champ_index]
        row_id = champ.row_id
        following_champ = ordered_champs[champ_index + 1..-1].find do |c|
          next if c.row_id.present? && c.row_id != row_id # ignorer les champs d'une ligne différente

          (c.type == 'Champs::VisaChamp' && c.value.present?) ||
          (c.type == 'Champs::HeaderSectionChamp' && c.header_section_level_value == 1)
        end
        # modification rejetée si l'élement qui suit est un visa
        to_reject = following_champ.present? && following_champ.type == 'Champs::VisaChamp'
        Rails.logger.warn("Annulation sauvegarde de l'annotation '#{champ.libelle}' sur dossier #{dossier_with_champs.id} car le visa '#{following_champ.libelle}' est validé.") if to_reject
        to_reject
      end
      champs_private_attributes_params
    end

    def mark_demande_as_read
      current_instructeur.mark_tab_as_seen(dossier, :demande)
    end

    def mark_messagerie_as_read
      current_instructeur.mark_tab_as_seen(dossier, :messagerie)
    end

    def mark_avis_as_read
      current_instructeur.mark_tab_as_seen(dossier, :avis)
    end

    def mark_annotations_privees_as_read
      current_instructeur.mark_tab_as_seen(dossier, :annotations_privees)
    end

    def aasm_error_message(exception, target_state:)
      if exception.originating_state == target_state
        "Le dossier est déjà #{dossier_display_state(target_state, lower: true)}."
      elsif exception.failures.include?(:can_terminer?) && dossier.any_etablissement_as_degraded_mode?
        "Les données relatives au SIRET de ce dossier n’ont pas pu encore être vérifiées : il n’est pas possible de le passer #{dossier_display_state(target_state, lower: true)}."
      else
        "Le dossier est en ce moment #{dossier_display_state(exception.originating_state, lower: true)} : il n’est pas possible de le passer #{dossier_display_state(target_state, lower: true)}."
      end
    end

    def redirect_on_dossier_not_found
      if !dossier_scope.exists?(id: params[:dossier_id])
        Rails.logger.debug { "Redirecting because dossier ID #{params[:dossier_id]} not found in scope." }
        redirect_to instructeur_procedure_path(procedure)
      end
    end

    def redirect_on_dossier_in_batch_operation
      dossier_in_batch = begin
        dossier
                         rescue ActiveRecord::RecordNotFound
                           Rails.logger.debug { "Dossier not found in batch operation for ID: #{params[:dossier_id]}" }
                           current_instructeur.dossiers.find(params[:dossier_id])
      end
      if dossier_in_batch.batch_operation.present?
        Rails.logger.debug { "Redirecting because dossier ID #{params[:dossier_id]} is part of a batch operation." }
        flash.alert = "Votre action n'a pas été effectuée, ce dossier fait parti d'un traitement de masse."
        redirect_back(fallback_location: instructeur_dossier_path(procedure, dossier_in_batch))
      end
    end
  end
end
