# frozen_string_literal: true

module SimpliscoreConcern
  extend ActiveSupport::Concern

  included do
    before_action :ensure_simpliscore_enabled, only: [:simplify, :accept_simplification, :enqueue_simplify, :poll_simplify]

    def enqueue_simplify
      if llm_rule_suggestion_scope.where(rule:).exists?(state: [:queued, :running])
        redirect_to simplify_admin_procedure_types_de_champ_path(@procedure, rule:), notice: 'Une recherche est déjà en cours pour cette règle.'
      else
        LLM::ImproveProcedureJob.perform_now(@procedure, rule, action: action_name, user_id: current_administrateur.user.id) # nothing async, the job re-enqueues a GenerateRuleSuggestionJob
        redirect_to simplify_admin_procedure_types_de_champ_path(@procedure, rule:), notice: 'La recherche a été lancée. Vous serez prévenu(e) lorsque les suggestions seront prêtes.'
      end
    end

    def simplify
      @llm_rule_suggestion = llm_rule_suggestion_scope
        .where(rule:)
        .includes(:llm_rule_suggestion_items)
        .order(created_at: :desc)
        .first

      if @llm_rule_suggestion&.finished?
        next_rule = LLMRuleSuggestion.next_rule(params[:rule])

        if next_rule
          redirect_to simplify_admin_procedure_types_de_champ_path(@procedure, rule: next_rule),
                      notice: "Toutes les suggestions pour la règle « #{LLM::StepperComponent.step_title(rule)} » ont déjà été examinées. Continuons avec la règle « #{LLM::StepperComponent.step_title(next_rule)} »."
        elsif tunnel_can_restart?
          redirect_to simplify_admin_procedure_types_de_champ_path(@procedure, rule: LLMRuleSuggestion::RULE_SEQUENCE.first),
                      notice: "Le formulaire a évolué depuis la dernière analyse. Vous pouvez relancer une nouvelle analyse."
        end
      elsif tunnel_can_restart? && rule != LLMRuleSuggestion::RULE_SEQUENCE.first
        # Tunnel finished with schema change: redirect any non-first step to step 1
        redirect_to simplify_admin_procedure_types_de_champ_path(@procedure, rule: LLMRuleSuggestion::RULE_SEQUENCE.first),
                    notice: "Le formulaire a évolué depuis la dernière analyse. Vous pouvez relancer une nouvelle analyse."
      end

      @llm_rule_suggestion ||= draft.llm_rule_suggestions.build(rule:)
    end

    def poll_simplify
      @llm_rule_suggestion = llm_rule_suggestion_scope
        .where(rule: rule)
        .order(created_at: :desc)
        .first

      if @llm_rule_suggestion&.state&.in?(['completed', 'failed'])
        render turbo_stream: turbo_stream.refresh
      else
        head :no_content
      end
    end

    def accept_simplification
      @llm_rule_suggestion = llm_rule_suggestion_scope.completed.includes(:llm_rule_suggestion_items).where(id: params[:llm_suggestion_rule_id]).first
      return redirect_to(simplify_index_admin_procedure_types_de_champ_path(@procedure), alert: "Suggestion non trouvée") unless @llm_rule_suggestion

      ActiveRecord::Base.transaction do
        if @llm_rule_suggestion.llm_rule_suggestion_items.empty?
          @llm_rule_suggestion.skipped!
        else
          @llm_rule_suggestion.assign_attributes(suggestion_items_attributes)
          @llm_rule_suggestion.save!
          @procedure.draft_revision.apply_llm_rule_suggestion_items(@llm_rule_suggestion.changes_to_apply)
          @llm_rule_suggestion.accepted!
        end
      end

      next_rule = LLMRuleSuggestion.next_rule(@llm_rule_suggestion.rule)

      if next_rule
        redirect_to simplify_admin_procedure_types_de_champ_path(@procedure, rule: next_rule), notice: "Parfait, continuons"
      else
        # Tunnel complete - redirect to champs page with appropriate message
        # Reset memoized values to reflect post-apply state
        remove_instance_variable(:@current_schema_hash) if defined?(@current_schema_hash)

        if first_rule_suggestion&.schema_hash != current_schema_hash
          redirect_to champs_admin_procedure_path(@procedure),
                      notice: "Toutes les suggestions ont été examinées. Le formulaire a évolué, vous pouvez relancer une nouvelle analyse."
        else
          redirect_to champs_admin_procedure_path(@procedure),
                      notice: "Toutes les suggestions ont été examinées."
        end
      end
    end

    private

    def ensure_simpliscore_enabled
      return if @procedure.feature_enabled?(:llm_nightly_improve_procedure)

      redirect_to admin_procedure_path(@procedure), alert: "Les appels aux modèles de langage ne sont pas activés pour cette procédure."
    end

    def rule
      params[:rule]
    end

    def llm_rule_suggestion_scope
      scope = LLMRuleSuggestion.where(procedure_revision_id: draft.id)

      if LLMRuleSuggestion.position_for(rule) == 1
        scope.where(schema_hash: current_schema_hash)
      else
        scope.where(created_at: tunnel_first_step.created_at..)
      end
    end

    def current_schema_hash
      @current_schema_hash ||= Digest::SHA256.hexdigest(draft.schema_to_llm.to_json)
    end

    def tunnel_first_step
      @tunnel_first_step ||= LLMRuleSuggestion
        .where(
          procedure_revision_id: draft.id,
          rule: LLMRuleSuggestion::RULE_SEQUENCE.first
        )
        .order(created_at: :desc)
        .first
    end

    def suggestion_items_attributes
      params.require(:llm_rule_suggestion)
        .permit(llm_rule_suggestion_items_attributes: [:id, :verify_status])
    end
  end
end
