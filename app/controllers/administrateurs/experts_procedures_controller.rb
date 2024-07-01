module Administrateurs
  class ExpertsProceduresController < AdministrateurController
    include EmailSanitizableConcern
    before_action :retrieve_procedure
    before_action :retrieve_experts_procedure, only: [:index, :create]
    before_action :retrieve_experts_emails, only: [:index, :create]

    def index
    end

    def create
      emails = params['emails'].presence || [].to_json
      emails = JSON.parse(emails).map { EmailSanitizer.sanitize(_1) }
      @maybe_typo, emails = emails
        .map { |email| [email, EmailChecker.check(email:)[:suggestions]&.first] }
        .partition { _1[1].present? }
      errors = if !@maybe_typo.empty?
        ["Attention, nous pensons avoir identifié une faute de frappe dans les invitations : #{@maybe_typo.map(&:first).join(', ')}"]
      else
        []
      end
      emails += [EmailSanitizer.sanitize(params['maybe_typo'])] if params['maybe_typo'].present?

      valid_users, invalid_users = emails
        .map { |email| User.create_or_promote_to_expert(email, SecureRandom.hex) }
        .partition(&:valid?)

      if invalid_users.any?
        errors += invalid_users
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

        flash.now[:notice] = t('.experts_assignment',
          count: valid_users.count,
          value: valid_users.map(&:email).join(', '),
          procedure: @procedure.id)
      end

      flash.now[:alert] = errors.join(". ") if !errors.empty?
      render :index
    end

    def update
      @procedure
        .experts_procedures
        .find(params[:id])
        .update!(expert_procedure_params)
    end

    def destroy
      expert_procedure = ExpertsProcedure.find_by!(procedure: @procedure, id: params[:id])
      expert_email = expert_procedure.expert.email
      expert_procedure.update!(revoked_at: Time.zone.now)
      flash[:notice] = "#{expert_email} a été révoqué de la démarche et ne pourra plus déposer d’avis."
      redirect_to admin_procedure_experts_path(@procedure)
    end

    private

    def retrieve_experts_procedure
      @experts_procedure ||= @procedure.experts_procedures.where(revoked_at: nil).sort_by { _1.expert.email }
    end

    def retrieve_experts_emails
      @experts_emails ||= @experts_procedure.map { _1.expert.email }
    end

    def expert_procedure_params
      params.require(:experts_procedure).permit(:allow_decision_access)
    end
  end
end
