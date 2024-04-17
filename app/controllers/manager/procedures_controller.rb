module Manager
  class ProceduresController < Manager::ApplicationController
    CSV_MAX_SIZE = 1.megabytes
    CSV_ACCEPTED_CONTENT_TYPES = [
      "text/csv",
      "application/vnd.ms-excel"
    ]
    #
    # Administrate overrides
    #

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    def scoped_resource
      if unfiltered_list?
        # Don't display discarded demarches in the unfiltered list…
        Procedure.kept
      else
        # … but allow them to be searched and displayed.
        Procedure.with_discarded
      end
    end

    def whitelist
      procedure.whitelist!
      flash[:notice] = "Démarche whitelistée."
      redirect_to manager_procedure_path(procedure)
    end

    def hide_as_template
      procedure.hide_as_template!
      flash[:notice] = "Démarche non visible dans les modèles."
      redirect_to manager_procedure_path(procedure)
    end

    def unhide_as_template
      procedure.unhide_as_template!
      flash[:notice] = "Démarche visible dans les modèles."
      redirect_to manager_procedure_path(procedure)
    end

    def discard
      procedure.discard_and_keep_track!(current_super_admin)

      logger.info("La démarche #{procedure.id} est supprimée par #{current_super_admin.email}")
      flash[:notice] = "La démarche #{procedure.id} a été supprimée."

      redirect_to manager_procedure_path(procedure)
    end

    def restore
      procedure.restore(current_super_admin)

      flash[:notice] = "La démarche #{procedure.id} a été restauré."

      redirect_to manager_procedure_path(procedure)
    end

    def export_mail_brouillons
      dossiers = procedure.dossiers.state_brouillon.includes(:user)
      emails = dossiers.map { |dossier| dossier.user_email_for(:display) }.sort.uniq
      date = Time.zone.now.strftime('%d-%m-%Y')
      send_data(emails.join("\n"), :filename => "brouillons-#{procedure.id}-au-#{date}.csv")
    end

    def add_administrateur_and_instructeur
      administrateur = Administrateur.by_email(current_super_admin.email)
      instructeur = Instructeur.by_email(current_super_admin.email)
      if administrateur && instructeur
        ActiveRecord::Base.transaction do
          AdministrateursProcedure.create!(procedure: procedure, administrateur: administrateur, manager: true)
          procedure.groupe_instructeurs.map do |groupe_instructeur|
            instructeur.assign_to.create(groupe_instructeur: groupe_instructeur, manager: true)
          end
        end

        flash[:notice] = "L’administrateur \"#{administrateur.email}\" a été ajouté à la démarche. L'instructeur \"#{instructeur.email}\" a été ajouté aux #{procedure.groupe_instructeurs.count} groupes d'instructeurs"
      else
        flash[:alert] = "L’administrateur \"#{administrateur.email}\" est introuvable."
      end
      redirect_to manager_procedure_path(procedure)
    end

    def add_administrateur_with_confirmation
      redirect_to new_manager_procedure_confirmation_url_path(procedure, email: params[:email])
    end

    def delete_administrateur
      administrateur = procedure.administrateurs.find { |admin| admin.email == current_super_admin.email }
      if administrateur.present?
        procedure.administrateurs.delete(administrateur)
      end

      instructeur = Instructeur.by_email(current_super_admin.email)
      if instructeur.present?
        procedure.groupe_instructeurs.map do |groupe_instructeur|
          groupe_instructeur.assign_tos.where(instructeur: instructeur).destroy_all
        end
      end

      redirect_to manager_procedure_path(procedure)
    end

    def change_piece_justificative_template
      if type_de_champ.update(type_de_champ_params)
        flash[:notice] = "Le modèle est mis à jour."
      else
        flash[:alert] = type_de_champ.errors.full_messages.join(', ')
      end
      redirect_to manager_procedure_path(procedure)
    end

    def add_tags
      tags_h = { tags: JSON.parse(tags_params[:tags]) }
      if procedure.update(tags_h)
        flash.notice = "Le modèle est mis à jour."
      else
        flash.alert = procedure.errors.full_messages.join(', ')
      end
      redirect_to manager_procedure_path(procedure)
    end

    def update_template_status
      if procedure.update(template_params)
        redirect_to manager_procedure_path(procedure), notice: 'Le statut de modèle a été mis à jour.'
      else
        flash.alert = procedure.errors.full_messages.join(', ')
      end
    end

    def import_data
    end

    def import_tags
      if !CSV_ACCEPTED_CONTENT_TYPES.include?(tags_csv_file.content_type) && !CSV_ACCEPTED_CONTENT_TYPES.include?(marcel_content_type)
        flash[:alert] = "Importation impossible : veuillez importer un fichier CSV"

      elsif tags_csv_file.size > CSV_MAX_SIZE
        flash[:alert] = "Importation impossible : le poids du fichier est supérieur à #{number_to_human_size(CSV_MAX_SIZE)}"

      else
        file = tags_csv_file.read
        base_encoding = CharlockHolmes::EncodingDetector.detect(file)
        procedure_tags = ACSV::CSV.new_for_ruby3(file.encode("UTF-8", base_encoding[:encoding], invalid: :replace, replace: ""), headers: true, header_converters: :downcase)
          .map { |r| r.to_h.slice('demarche', 'tag') }

        invalid_ids = []
        procedure_tags.each do |procedure_tag|
          procedure = Procedure.find_by(id: procedure_tag['demarche'])
          tags = procedure_tag["tag"].split(',').map(&:strip).map(&:capitalize)

          if procedure.nil?
            invalid_ids << procedure_tag['demarche']
            next
          end

          tags.each do |tag|
            procedure.tags.push(tag)
          end
          procedure.save
        end
      end
      message =  "Import des tags terminé."
      message += " Ces démarches n'existent pas : #{invalid_ids.to_sentence}" if invalid_ids.any?
      flash.notice = message
      redirect_to manager_administrateurs_path
    end

    private

    def procedure
      @procedure ||= Procedure.with_discarded.find(params[:id])
    end

    def type_de_champ
      TypeDeChamp.find(params[:type_de_champ][:id])
    end

    def type_de_champ_params
      params.require(:type_de_champ).permit(:piece_justificative_template)
    end

    def tags_params
      params.require(:procedure).permit(:tags)
    end

    def template_params
      params.require(:procedure).permit(:template)
    end

    def tags_csv_file
      params[:tags_csv_file]
    end

    def marcel_content_type
      Marcel::MimeType.for(tags_csv_file.read, name: tags_csv_file.original_filename, declared_type: tags_csv_file.content_type)
    end

    def unfiltered_list?
      action_name == "index" && !params[:search]
    end
  end
end
