module Instructeurs
  class ProcedurePresentationsController < InstructeurController
    before_action :ensure_ownership!
    before_action :procedure_presentation

    def add_row
      condition = Logic.add_empty_condition_to(procedure_presentation.conditions)
      procedure_presentation.update!(conditions: condition)
      @instructeur_filter_component = build_instructeur_filter_component
    end

    def delete_row
      condition = condition_form.delete_row(row_index).to_condition
      procedure_presentation.update!(conditions: condition)

      @instructeur_filter_component = build_instructeur_filter_component
    end

    def update
      condition = condition_form.to_condition
      procedure_presentation.update!(conditions: condition)

      @instructeur_filter_component = build_instructeur_filter_component
    end

    def change_targeted_champ
      condition = condition_form.change_champ(row_index).to_condition
      procedure_presentation.update!(conditions: condition)
      @instructeur_filter_component = build_instructeur_filter_component
    end

    private

    ### condition utils
    def build_instructeur_filter_component
      Conditions::InstructeurFilterComponent.new(procedure: @procedure, procedure_presentation: @procedure_presentation)
    end

    def published_revision = nil
    def condition_form = nil
    def instructeur_fitler_params = nil
    def row_index = nil

    ### controller utils
    def procedure_id = params[:procedure_id]

    def procedure
      @procedure ||= Procedure
        .with_attached_logo
        .find(procedure_id)
        .tap { Sentry.set_tags(procedure: _1.id) }
    end

    def ensure_ownership!
      if !current_instructeur.procedures.include?(procedure)
        flash[:alert] = "Vous n’avez pas accès à cette démarche"
        redirect_to root_path
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
  end
end
