module NewAdministrateur
  class ExpertsProceduresController < AdministrateurController
    before_action :retrieve_procedure, only: [:add_expert_to_procedure, :revoke_expert_from_procedure]

    def add_expert_to_procedure
      emails = params['emails'].presence || [].to_json
      emails = JSON.parse(emails).map(&:strip).map(&:downcase)

      valid_users, invalid_users = emails
        .map { |email| User.create_or_promote_to_expert(email, SecureRandom.hex) }
        .partition(&:valid?)

      if invalid_users.any?
        flash[:alert] = invalid_users
          .filter { |user| user.errors.present? }
          .map { |user| "#{user.email} : #{user.errors.full_messages_for(:email).join(', ')}" }
      end

      if valid_users.present?
        valid_users.each do |user|
          experts_procedure = ExpertsProcedure.find_or_create_by(expert: user.expert, procedure: @procedure)
          if !experts_procedure.revoked_at.nil?
            experts_procedure.update!(revoked_at: nil)
          end
        end

        flash[:notice] = t('.experts_assignment',
          count: valid_users.count,
          value: valid_users.map(&:email).join(', '),
          procedure: @procedure.id)
      end
      redirect_to admin_procedure_invited_expert_list_path(@procedure)
    end

    def revoke_expert_from_procedure
      expert_procedure = ExpertsProcedure.find_by!(procedure: @procedure, id: params[:id])
      expert_email = expert_procedure.expert.email
      expert_procedure.update!(revoked_at: Time.zone.now)
      flash[:notice] = "#{expert_email} a été révoqué de la démarche et ne pourra plus déposer d'avis."
      redirect_to admin_procedure_invited_expert_list_path(@procedure)
    end
  end
end
