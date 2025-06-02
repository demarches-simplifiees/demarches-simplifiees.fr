# frozen_string_literal: true

module Manager
  class AdministrateursController < Manager::ApplicationController
    def create
      administrateur = current_super_admin.invite_admin(create_administrateur_params[:email])

      if administrateur.errors.empty?
        flash.notice = "Administrateur créé"
        redirect_to manager_administrateurs_path
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, administrateur)
        }
      end
    end

    def reinvite
      Administrateur.find_inactive_by_id(params[:id]).user.invite_administrateur!
      flash.notice = "Invitation renvoyée"
      redirect_to manager_administrateur_path(params[:id])
    end

    def delete
      administrateur = Administrateur.find(params[:id])

      result = AdministrateurDeletionService.new(current_super_admin, administrateur).call

      case result
      in Dry::Monads::Result::Success
        logger.info("L'administrateur #{administrateur.id} est supprimé par #{current_super_admin.id}")
        flash[:notice] = "L'administrateur #{administrateur.id} est supprimé"
      in Dry::Monads::Result::Failure(reason)
        flash[:alert] = I18n.t(reason, scope: "manager.administrateurs.delete")
      end

      redirect_to manager_administrateurs_path
    end

    def data_exports
    end

    def export_last_month
      administrateurs = Administrateur.joins(:user).where(created_at: 6.months.ago..).where.not(users: { email_verified_at: nil })
      csv = CSV.generate(headers: true) do |csv|
        csv << ['ID', 'Email', 'Date de création']
        administrateurs.each do |administrateur|
          csv << [administrateur.id, administrateur.email, administrateur.created_at]
        end
      end

      send_data csv, filename: "administrateurs_#{Date.today.strftime('%d-%m-%Y')}.csv"
    end

    private

    def create_administrateur_params
      params.require(:administrateur).permit(:email)
    end
  end
end
