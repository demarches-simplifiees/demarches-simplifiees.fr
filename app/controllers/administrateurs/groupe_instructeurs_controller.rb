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

      if procedure.routee?
        @groupes_instructeurs = paginated_groupe_instructeurs
        @instructeurs = []
        @available_instructeur_emails = []
      else
        @groupes_instructeurs = []
        @instructeurs = paginated_instructeurs
        @available_instructeur_emails = available_instructeur_emails
      end
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
        redirect_to admin_procedure_groupe_instructeur_path(procedure, @groupe_instructeur),
          notice: "Le groupe d’instructeurs « #{@groupe_instructeur.label} » a été créé."
      else
        @procedure = procedure
        @groupes_instructeurs = paginated_groupe_instructeurs

        flash[:alert] = "le nom « #{@groupe_instructeur.label} » est déjà pris par un autre groupe."
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

        flash[:alert] = "le nom « #{@groupe_instructeur.label} » est déjà pris par un autre groupe."
        render :show
      end
    end

    def destroy
      @groupe_instructeur = groupe_instructeur

      if !@groupe_instructeur.dossiers.empty?
        flash[:alert] = "Impossible de supprimer un groupe avec des dossiers. Il faut le réaffecter avant"
      elsif procedure.groupe_instructeurs.one?
        flash[:alert] = "Suppression impossible : il doit y avoir au moins un groupe instructeur sur chaque procédure"
      else
        @groupe_instructeur.destroy!
        flash[:notice] = "le groupe « #{@groupe_instructeur.label} » a été supprimé."
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
      emails = JSON.parse(emails).map(&:strip).map(&:downcase)

      correct_emails, bad_emails = emails
        .partition { |email| URI::MailTo::EMAIL_REGEXP.match?(email) }

      if bad_emails.present?
        flash[:alert] = t('.wrong_address',
          count: bad_emails.count,
          value: bad_emails.join(', '))
      end

      email_to_adds = correct_emails - groupe_instructeur.instructeurs.map(&:email)

      if email_to_adds.present?
        instructeurs = email_to_adds.map do |instructeur_email|
          Instructeur.by_email(instructeur_email) ||
            create_instructeur(instructeur_email)
        end

        if procedure.routee?
          instructeurs.each do |instructeur|
            groupe_instructeur.add(instructeur)
          end

          GroupeInstructeurMailer
            .add_instructeurs(groupe_instructeur, instructeurs, current_user.email)
            .deliver_later

          flash[:notice] = t('.assignment',
            count: email_to_adds.count,
            value: email_to_adds.join(', '),
            groupe: groupe_instructeur.label)

        else

          if instructeurs.present?
            instructeurs.each do |instructeur|
              procedure.defaut_groupe_instructeur.add(instructeur)
            end
            flash[:notice] = "Les instructeurs ont bien été affectés à la démarche"
          end
        end
      end

      if procedure.routee?
        redirect_to admin_procedure_groupe_instructeur_path(procedure, groupe_instructeur)
      else
        redirect_to admin_procedure_groupe_instructeurs_path(procedure)
      end
    end

    def remove_instructeur
      if groupe_instructeur.instructeurs.one?
        flash[:alert] = "Suppression impossible : il doit y avoir au moins un instructeur dans le groupe"
      else
        instructeur = Instructeur.find(instructeur_id)
        if procedure.routee?
          if groupe_instructeur.remove(instructeur)
            flash[:notice] = "L’instructeur « #{instructeur.email} » a été retiré du groupe."
            GroupeInstructeurMailer
              .remove_instructeur(groupe_instructeur, instructeur, current_user.email)
              .deliver_later
          else
            flash[:alert] = "L’instructeur « #{instructeur.email} » n’est pas dans le groupe."
          end
        else
          if procedure.defaut_groupe_instructeur.remove(instructeur)
            flash[:notice] = "L’instructeur a bien été désaffecté de la démarche"
          else
            flash[:alert] = "L’instructeur n’est pas affecté à la démarche"
          end
        end
      end

      if procedure.routee?
        redirect_to admin_procedure_groupe_instructeur_path(procedure, groupe_instructeur)
      else
        redirect_to admin_procedure_groupe_instructeurs_path(procedure)
      end
    end

    def update_routing_criteria_name
      procedure.update!(routing_criteria_name: routing_criteria_name)

      redirect_to admin_procedure_groupe_instructeurs_path(procedure),
        notice: "Le libellé est maintenant « #{procedure.routing_criteria_name} »."
    end

    def update_routing_enabled
      procedure.update!(routing_enabled_params)

      redirect_to admin_procedure_groupe_instructeurs_path(procedure),
      notice: "Le routage est #{procedure.routing_enabled? ? "activée" : "désactivée"}."
   end

    def update_instructeurs_self_management_enabled
      procedure.update!(instructeurs_self_management_enabled_params)

      redirect_to admin_procedure_groupe_instructeurs_path(procedure),
      notice: "L’autogestion des instructeurs est #{procedure.instructeurs_self_management_enabled? ? "activée" : "désactivée"}."
    end

    def import
      if procedure.publiee?
        if !CSV_ACCEPTED_CONTENT_TYPES.include?(group_csv_file.content_type) && !CSV_ACCEPTED_CONTENT_TYPES.include?(marcel_content_type)
          flash[:alert] = "Importation impossible : veuillez importer un fichier CSV"

        elsif group_csv_file.size > CSV_MAX_SIZE
          flash[:alert] = "Importation impossible : le poids du fichier est supérieur à #{number_to_human_size(CSV_MAX_SIZE)}"

        else
          file = group_csv_file.read
          base_encoding = CharlockHolmes::EncodingDetector.detect(file)
          groupes_emails = ACSV::CSV.new_for_ruby3(file.encode("UTF-8", base_encoding[:encoding], invalid: :replace, replace: ""), headers: true, header_converters: :downcase)
            .map { |r| r.to_h.slice('groupe', 'email') }

          groupes_emails_has_keys = groupes_emails.first.has_key?("groupe") && groupes_emails.first.has_key?("email")

          if groupes_emails_has_keys.blank?
            flash[:alert] = "Importation impossible, veuillez importer un csv #{view_context.link_to('suivant ce modèle', "/csv/#{I18n.locale}/import-groupe-test.csv")}"
          else
            add_instructeurs_and_get_errors = InstructeursImportService.import(procedure, groupes_emails)

            if add_instructeurs_and_get_errors.empty?
              flash[:notice] = "La liste des instructeurs a été importée avec succès"
            else
              flash[:alert] = "Import terminé. Cependant les emails suivants ne sont pas pris en compte: #{add_instructeurs_and_get_errors.join(', ')}"
            end
          end
        end
        redirect_to admin_procedure_groupe_instructeurs_path(procedure)
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

    def create_instructeur(email)
      user = User.create_or_promote_to_instructeur(
        email,
        SecureRandom.hex,
        administrateurs: [current_administrateur]
      )
      user.invite!
      user.instructeur
    end

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
        .order(:label)
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

    def group_csv_file
      params[:group_csv_file]
    end

    def marcel_content_type
      Marcel::MimeType.for(group_csv_file.read, name: group_csv_file.original_filename, declared_type: group_csv_file.content_type)
    end

    def instructeurs_self_management_enabled_params
      params.require(:procedure).permit(:instructeurs_self_management_enabled)
    end

    def routing_enabled_params
      { routing_enabled: params.require(:routing) == 'enable' }
    end
  end
end
