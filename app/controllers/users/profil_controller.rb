module Users
  class ProfilController < UserController
    before_action :ensure_update_email_is_authorized, only: :update_email
    before_action :find_transfers, only: [:show]

    def show
      @france_connect_informations = FranceConnectInformation.where(user: current_user)
    end

    def update_email
      requested_user = User.find_by(email: requested_email)
      if requested_user.present? && current_user.ask_for_merge(requested_user)
        current_user.update(unconfirmed_email: nil)

        flash.notice = t('devise.registrations.update_needs_confirmation')
      elsif current_user.update(update_email_params)
        current_user.update(requested_merge_into: nil)

        flash.notice = t('devise.registrations.update_needs_confirmation')
      else
        flash.alert = current_user.errors.full_messages
      end

      redirect_to profil_path
    end

    def transfer_all_dossiers
      transfer = DossierTransfer.initiate(next_owner_email, current_user.dossiers)

      if transfer.valid?
        flash.notice = t('.new_transfer', count: current_user.dossiers.count, email: next_owner_email)
      else
        flash.alert = transfer.errors.full_messages
      end

      redirect_to profil_path
    end

    def accept_merge
      users_requesting_merge.each { |user| current_user.merge(user) }
      users_requesting_merge.update_all(requested_merge_into_id: nil)

      flash.notice = "Vous avez absorbé le compte #{waiting_merge_emails.join(', ')}"
      redirect_to profil_path
    end

    def refuse_merge
      users = users_requesting_merge
      users.update_all(requested_merge_into_id: nil)

      flash.notice = 'La fusion a été refusé'
      redirect_to profil_path
    end

    def destroy_fci
      fci = FranceConnectInformation
        .where(user: current_user)
        .find(params[:fci_id])

      fci.destroy!
      flash.notice = "Le compte FranceConnect de « #{fci.full_name} » ne peut plus accéder à vos dossiers"

      redirect_to profil_path
    end

    def preferred_domain
      current_user.update_preferred_domain(request.host_with_port)

      head :no_content
    end

    private

    def find_transfers
      @waiting_merge_emails = waiting_merge_emails
      @waiting_transfers = current_user.dossiers.joins(:transfer).group('dossier_transfers.email').count.to_a
    end

    def waiting_merge_emails
      users_requesting_merge.pluck(:email)
    end

    def users_requesting_merge
      @requesting_merge ||= current_user.requested_merge_from
    end

    def ensure_update_email_is_authorized
      if current_user.instructeur? && !target_email_allowed?
        flash.alert = t('users.profil.ensure_update_email_is_authorized.email_not_allowed', contact_email: Current.contact_email, requested_email: requested_email)
        redirect_to profil_path
      end
    end

    def update_email_params
      params.require(:user).permit(:email)
    end

    def requested_email
      update_email_params[:email]
    end

    def target_email_allowed?
      LEGIT_ADMIN_DOMAINS.any? { |d| requested_email.end_with?(d) }
    end

    def next_owner_email
      params[:next_owner]
    end
  end
end
