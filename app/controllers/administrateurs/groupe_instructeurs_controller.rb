module Administrateurs
  class GroupeInstructeursController < AdministrateurController
    include ActiveSupport::NumberHelper

    before_action :ensure_not_super_admin!, only: [:add_instructeur]

    ITEMS_PER_PAGE = 25
    CSV_MAX_SIZE = 1.megabytes
    CSV_ACCEPTED_CONTENT_TYPES = [
      "text/csv",
      "application/vnd.ms-excel"
    ]

    def index
      @procedure = procedure
      @groupes_instructeurs = paginated_groupe_instructeurs

      @instructeurs = paginated_instructeurs
      @available_instructeur_emails = available_instructeur_emails
    end

    def show
      @procedure = procedure
      @groupe_instructeur = groupe_instructeur
      @instructeurs = paginated_instructeurs
      @available_instructeur_emails = available_instructeur_emails
    end

    def create
      @groupe_instructeur = procedure
        .groupe_instructeurs
        .new({ instructeurs: [current_administrateur.instructeur] }.merge(groupe_instructeur_params))

      if @groupe_instructeur.save
        routing_notice = " et le routage a été activé" if procedure.groupe_instructeurs.active.size == 2
        redirect_to admin_procedure_groupe_instructeur_path(procedure, @groupe_instructeur),
          notice: "Le groupe d’instructeurs « #{@groupe_instructeur.label} » a été créé#{routing_notice}."
      else
        @procedure = procedure
        @instructeurs = paginated_instructeurs
        @groupes_instructeurs = paginated_groupe_instructeurs

        flash.now[:alert] = @groupe_instructeur.errors.full_messages
        render :index
      end
    end

    def update
      @groupe_instructeur = groupe_instructeur

      if @groupe_instructeur.update(groupe_instructeur_params)
        redirect_to admin_procedure_groupe_instructeur_path(procedure, groupe_instructeur),
          notice: "Le nom est à présent « #{@groupe_instructeur.label} »."
      else
        @procedure = procedure
        @instructeurs = paginated_instructeurs
        @available_instructeur_emails = available_instructeur_emails

        flash.now[:alert] = @groupe_instructeur.errors.full_messages
        render :show
      end
    end

    def destroy
      @groupe_instructeur = groupe_instructeur

      if @groupe_instructeur.dossiers.present?
        flash[:alert] = "Impossible de supprimer un groupe avec des dossiers. Il faut le réaffecter avant"
      elsif procedure.groupe_instructeurs.one?
        flash[:alert] = "Suppression impossible : il doit y avoir au moins un groupe instructeur sur chaque procédure"
      elsif @groupe_instructeur.id == procedure.defaut_groupe_instructeur.id
        flash[:alert] = "Suppression impossible : le groupe « #{@groupe_instructeur.label} » est le groupe par défaut."
      else
        @groupe_instructeur.destroy!
        if procedure.groupe_instructeurs.active.one?
          procedure.update!(routing_enabled: false)
          routing_notice = " et le routage a été désactivé"
        end
        flash[:notice] = "le groupe « #{@groupe_instructeur.label} » a été supprimé#{routing_notice}."
      end
      redirect_to admin_procedure_groupe_instructeurs_path(procedure)
    end

    def reaffecter_dossiers
      @procedure = procedure
      @groupe_instructeur = groupe_instructeur
      @groupes_instructeurs = paginated_groupe_instructeurs
        .without_group(@groupe_instructeur)
    end

    def reaffecter_bulk_messages(target_group)
      bulk_messages = BulkMessage.joins(:groupe_instructeurs).where(groupe_instructeurs: { id: groupe_instructeur.id })
      bulk_messages.each do |bulk_message|
        bulk_message.groupe_instructeurs.delete(groupe_instructeur)
        if !bulk_message.groupe_instructeur_ids.include?(target_group.id)
          bulk_message.groupe_instructeurs << target_group
        end
      end
    end

    def reaffecter
      target_group = procedure.groupe_instructeurs.find(params[:target_group])
      reaffecter_bulk_messages(target_group)
      groupe_instructeur.dossiers.find_each do |dossier|
        dossier.assign_to_groupe_instructeur(target_group, current_administrateur)
      end

      flash[:notice] = "Les dossiers du groupe « #{groupe_instructeur.label} » ont été réaffectés au groupe « #{target_group.label} »."
      redirect_to admin_procedure_groupe_instructeurs_path(procedure)
    end

    def add_instructeur
      emails = params['emails'].presence || [].to_json
      emails = JSON.parse(emails).map { EmailSanitizableConcern::EmailSanitizer.sanitize(_1) }

      instructeurs, invalid_emails = groupe_instructeur.add_instructeurs(emails:)

      if invalid_emails.present?
        flash[:alert] = t('.wrong_address',
          count: invalid_emails.size,
          emails: invalid_emails.join(', '))
      end

      if instructeurs.present?
        flash[:notice] = if procedure.routing_enabled?
          t('.assignment',
            count: instructeurs.size,
            emails: instructeurs.map(&:email).join(', '),
            groupe: groupe_instructeur.label)
        else
          "Les instructeurs ont bien été affectés à la démarche"
        end

        GroupeInstructeurMailer
          .notify_added_instructeurs(groupe_instructeur, instructeurs, current_administrateur.email)
          .deliver_later
      end

      if procedure.routing_enabled?
        redirect_to admin_procedure_groupe_instructeur_path(procedure, groupe_instructeur)
      else
        redirect_to admin_procedure_groupe_instructeurs_path(procedure)
      end
    end

    def remove_instructeur
      if groupe_instructeur.instructeurs.one?
        flash[:alert] = "Suppression impossible : il doit y avoir au moins un instructeur dans le groupe"
      else
        instructeur = groupe_instructeur.instructeurs.find_by(id: instructeur_id)

        if groupe_instructeur.remove(instructeur)
          flash[:notice] = if instructeur.in?(procedure.instructeurs)
            "L’instructeur « #{instructeur.email} » a été retiré du groupe."
          else
            "L’instructeur a bien été désaffecté de la démarche"
          end
          GroupeInstructeurMailer
            .notify_removed_instructeur(groupe_instructeur, instructeur, current_administrateur.email)
            .deliver_later
        else
          flash[:alert] = if procedure.routing_enabled?
            if instructeur.present?
              "L’instructeur « #{instructeur.email} » n’est pas dans le groupe."
            else
              "L’instructeur n’est pas dans le groupe."
            end
          else
            "L’instructeur n’est pas affecté à la démarche"
          end
        end
      end

      if procedure.routing_enabled?
        redirect_to admin_procedure_groupe_instructeur_path(procedure, groupe_instructeur)
      else
        redirect_to admin_procedure_groupe_instructeurs_path(procedure)
      end
    end

    def update_routing_criteria_name
      if procedure.update(routing_criteria_name: routing_criteria_name)
        flash[:notice] = "Le libellé est maintenant « #{procedure.routing_criteria_name} »."
      else
        flash[:alert] = "Le libellé du routage doit être rempli."
      end
      redirect_to admin_procedure_groupe_instructeurs_path(procedure)
    end

    def update_instructeurs_self_management_enabled
      procedure.update!(instructeurs_self_management_enabled_params)

      redirect_to admin_procedure_groupe_instructeurs_path(procedure),
      notice: "L’autogestion des instructeurs est #{procedure.instructeurs_self_management_enabled? ? "activée" : "désactivée"}."
    end

    def import
      if procedure.publiee_or_close?
        if !CSV_ACCEPTED_CONTENT_TYPES.include?(csv_file.content_type) && !CSV_ACCEPTED_CONTENT_TYPES.include?(marcel_content_type)
          flash[:alert] = "Importation impossible : veuillez importer un fichier CSV"

        elsif csv_file.size > CSV_MAX_SIZE
          flash[:alert] = "Importation impossible : le poids du fichier est supérieur à #{number_to_human_size(CSV_MAX_SIZE)}"

        else
          file = csv_file.read
          base_encoding = CharlockHolmes::EncodingDetector.detect(file)

          csv_content = ACSV::CSV.new_for_ruby3(file.encode("UTF-8", base_encoding[:encoding], invalid: :replace, replace: ""), headers: true, header_converters: :downcase).map(&:to_h)

          if csv_content.first.has_key?("groupe") && csv_content.first.has_key?("email")
            groupes_emails = csv_content.map { |r| r.to_h.slice('groupe', 'email') }

            added_instructeurs_by_group, invalid_emails = InstructeursImportService.import_groupes(procedure, groupes_emails)

            added_instructeurs_by_group.each do |groupe, added_instructeurs|
              if added_instructeurs.present?
                GroupeInstructeurMailer
                  .notify_added_instructeurs(groupe, added_instructeurs, current_administrateur.email)
                  .deliver_later
              end
              flash_message_for_import(invalid_emails)
            end

          elsif csv_content.first.has_key?("email") && !csv_content.map(&:to_h).first.keys.many? && procedure.groupe_instructeurs.one?
            instructors_emails = csv_content.map(&:to_h)

            added_instructeurs, invalid_emails = InstructeursImportService.import_instructeurs(procedure, instructors_emails)
            if added_instructeurs.present?
              GroupeInstructeurMailer
                .notify_added_instructeurs(groupe_instructeur, added_instructeurs, current_administrateur.email)
                .deliver_later
            end
            flash_message_for_import(invalid_emails)
          else
            flash_message_for_invalid_csv
          end
          redirect_to admin_procedure_groupe_instructeurs_path(procedure)
        end
      end
    end

    def export_groupe_instructeurs
      groupe_instructeurs = procedure.groupe_instructeurs

      data = CSV.generate(headers: true) do |csv|
        column_names = ["Groupe", "Email"]
        csv << column_names
        groupe_instructeurs.each do |gi|
          gi.instructeurs.each do |instructeur|
            csv << [gi.label, instructeur.email]
          end
        end
      end

      respond_to do |format|
        format.csv { send_data data, filename: "#{procedure.id}-groupe-instructeurs-#{Date.today}.csv" }
      end
    end

    private

    def procedure
      current_administrateur
        .procedures
        .includes(:groupe_instructeurs)
        .find(params[:procedure_id])
    end

    def groupe_instructeur
      if params[:id].present?
        procedure.groupe_instructeurs.find(params[:id])
      else
        procedure.defaut_groupe_instructeur
      end
    end

    def instructeur_id
      params[:instructeur][:id]
    end

    def groupe_instructeur_params
      params.require(:groupe_instructeur).permit(:label, :closed)
    end

    def paginated_groupe_instructeurs
      procedure
        .groupe_instructeurs
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
    end

    def paginated_instructeurs
      groupe_instructeur
        .instructeurs
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(:email)
    end

    def routing_criteria_name
      params[:procedure][:routing_criteria_name]
    end

    def available_instructeur_emails
      all = current_administrateur.instructeurs.map(&:email)
      assigned = groupe_instructeur.instructeurs.map(&:email)
      (all - assigned).sort
    end

    def csv_file
      params[:csv_file]
    end

    def marcel_content_type
      Marcel::MimeType.for(csv_file.read, name: csv_file.original_filename, declared_type: csv_file.content_type)
    end

    def instructeurs_self_management_enabled_params
      params.require(:procedure).permit(:instructeurs_self_management_enabled)
    end

    def routing_enabled_params
      { routing_enabled: params.require(:routing) == 'enable' }
    end

    def flash_message_for_import(result)
      if result.blank?
        flash[:notice] = "La liste des instructeurs a été importée avec succès"
      else
        flash[:alert] = "Import terminé. Cependant les emails suivants ne sont pas pris en compte: #{result.join(', ')}"
      end
    end

    def flash_message_for_invalid_csv
      flash[:alert] = "Importation impossible, veuillez importer un csv suivant #{view_context.link_to('ce modèle', "/csv/import-instructeurs-test.csv")} pour une procédure sans routage ou #{view_context.link_to('celui-ci', "/csv/#{I18n.locale}/import-groupe-test.csv")} pour une procédure routée"
    end
  end
end
