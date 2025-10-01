# frozen_string_literal: true

require 'digest'

module Administrateurs
  class TypesDeChampController < AdministrateurController
    include ActiveSupport::NumberHelper
    include CsvParsingConcern
    include ActionView::Helpers::TagHelper

    before_action :retrieve_procedure
    before_action :reload_procedure_with_includes, only: [:destroy]

    def create
      type_de_champ = draft.add_type_de_champ(type_de_champ_create_params)
      if type_de_champ.valid?
        @coordinate = draft.coordinate_for(type_de_champ)
        ProcedureRevisionPreloader.load_one(@coordinate.revision)
        @created = champ_component_from(@coordinate, focused: true)
        @morphed = champ_components_starting_at(@coordinate, 1)
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def update
      import_referentiel and return if referentiel_file.present?

      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])
      @coordinate = draft.coordinate_for(type_de_champ)

      if @coordinate.used_by_routing_rules? && changing_of_type?(type_de_champ)
        errors = "« #{type_de_champ.libelle} » est utilisé pour le routage, vous ne pouvez pas modifier son type."
        @morphed = [champ_component_from(@coordinate, focused: false, errors:)]
        flash.alert = errors
      elsif type_de_champ.update(type_de_champ_update_params)
        reload_procedure_with_includes
        @morphed = champ_components_starting_at(@coordinate)
      else
        flash.alert = type_de_champ.errors.full_messages
      end
    end

    def piece_justificative_template
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

      if type_de_champ.piece_justificative_template.attach(params[:blob_signed_id])
        reload_procedure_with_includes
        @coordinate = draft.coordinate_for(type_de_champ)
        @morphed = [champ_component_from(@coordinate)]

        render :create
      else
        render json: { errors: @champ.errors.full_messages }, status: 422
      end
    end

    def notice_explicative
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

      if type_de_champ.notice_explicative.attach(params[:blob_signed_id])
        reload_procedure_with_includes
        @coordinate = draft.coordinate_for(type_de_champ)
        @morphed = [champ_component_from(@coordinate)]

        render :create
      else
        render json: { errors: @champ.errors.full_messages }, status: 422
      end
    end

    def move_and_morph
      source_type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])
      target_type_de_champ = draft.find_and_ensure_exclusive_use(params[:target_stable_id])
      @coordinate = draft.coordinate_for(source_type_de_champ)
      from = @coordinate.position
      to = draft.coordinate_for(target_type_de_champ).position # move after
      @coordinate = draft.move_type_de_champ_after(@coordinate.stable_id, to)
      reload_procedure_with_includes
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      @morphed = @coordinate.siblings
      if from > to # case of moved up, update components from target (> plus one) to origin
        @morphed = @morphed.filter { _1.position > to && _1.position <= from }
      else # case of moved down, update components from origin up to target (< minus one)
        @morphed = @morphed.filter { _1.position >= from && _1.position < to }
      end

      @morphed = @morphed.map { |c| champ_component_from(c) }
    end

    def move_up
      @coordinate = draft.move_up_type_de_champ(params[:stable_id])
      reload_procedure_with_includes
      @coordinate = draft.revision_types_de_champ.find { _1.id == @coordinate.id }
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      # update the one component below
      @morphed = champ_components_starting_at(@coordinate, 1).take(1)
    end

    def move_down
      @coordinate = draft.move_down_type_de_champ(params[:stable_id])
      reload_procedure_with_includes
      @coordinate = draft.revision_types_de_champ.find { _1.id == @coordinate.id }
      @destroyed = @coordinate
      @created = champ_component_from(@coordinate)
      # update the one component above
      @morphed = champ_components_starting_at(@coordinate, - 1).take(1)
    end

    def destroy
      coordinate, type_de_champ = draft.coordinate_and_tdc(params[:stable_id])

      if coordinate&.used_by_routing_rules?
        errors = "« #{type_de_champ.libelle} » est utilisé pour le routage, vous ne pouvez pas le supprimer."
        @morphed = [champ_component_from(coordinate, focused: false, errors:)]
        flash.alert = errors
      else
        @coordinate = draft.remove_type_de_champ(params[:stable_id])
        ProcedureRevisionPreloader.load_one(@coordinate.revision)
        if @coordinate.present?
          @destroyed = @coordinate
          @morphed = champ_components_starting_at(@coordinate)
        end
      end
    end

    def nullify_referentiel
      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])
      type_de_champ.update!(referentiel_id: nil)

      @coordinate = draft.coordinate_for(type_de_champ)
      @morphed = [champ_component_from(@coordinate)]
    end

    def import_referentiel
      return flash[:alert] = "Importation impossible : veuillez importer un fichier CSV" unless csv_file?
      return flash[:alert] = "Importation impossible : le poids du fichier est supérieur à #{number_to_human_size(CSV_MAX_SIZE)}" if referentiel_file.size > CSV_MAX_SIZE

      type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])
      csv_content = parse_csv(referentiel_file, keep_original_headers: true)

      return flash[:alert] = "Importation impossible : le fichier est vide ou mal interprété" if csv_content.empty?
      return flash[:alert] = "Importation impossible : votre fichier CSV fait plus de #{helpers.number_with_delimiter(CSV_MAX_LINES)} lignes" if csv_content.size > CSV_MAX_LINES

      headers = csv_content.first.keys
      digest = Digest::SHA256.hexdigest(csv_content.to_json)

      ActiveRecord::Base.transaction do
        referentiel = type_de_champ.create_referentiel!(
          name: referentiel_file.original_filename,
          headers: headers,
          type: 'Referentiels::CsvReferentiel',
          digest: digest
        )

        items_to_insert = csv_content.map do |row|
          {
            data: { row: row.transform_keys { Referentiel.header_to_path(_1) } },
            referentiel_id: referentiel.id
          }
        end

        ReferentielItem.insert_all(items_to_insert)
      end
    end

    def simplify_index
      @llm_rule_suggestions = llm_rule_suggestion_scope
        .joins(:llm_rule_suggestion_items)
        .select('llm_rule_suggestions.*, COUNT(llm_rule_suggestion_items.id) as items_count')
        .group('llm_rule_suggestions.id')
    end

    def simplify
      suggestion = llm_rule_suggestion_scope
        .where(id: params[:llm_suggestion_rule_id])
        .order(created_at: :desc)
        .first
      if suggestion
        component_class = LLM.const_get("#{suggestion.rule.camelcase}Component")
        @component = component_class.new(suggestion:)
      else
        redirect_to simplify_index_admin_procedure_types_de_champ_path(@procedure), alert: "Suggestion non trouvée"
      end
    end

    def accept_simplification
      @llm_rule_suggestion = llm_rule_suggestion_scope.includes(:llm_rule_suggestion_items).where(id: params[:llm_suggestion_rule_id]).first
      @llm_rule_suggestion.assign_attributes(llm_rule_suggestion_items_attributes)
      @llm_rule_suggestion.save!
      @procedure.draft_revision.apply_changes(@llm_rule_suggestion.changes_to_apply)

      redirect_to simplify_index_admin_procedure_types_de_champ_path(@procedure)
    end

    def llm_rule_suggestion_scope
      draft_revision = @procedure.draft_revision
      schema = draft_revision.schema_to_llm.to_json
      schema_hash = Digest::SHA256.hexdigest(schema)

      LLMRuleSuggestion.where(procedure_revision_id: draft_revision.id, state: 'completed', schema_hash:)
    end

    def llm_rule_suggestion_items_attributes
      params.require(:llm_rule_suggestion)
        .permit(llm_rule_suggestion_items_attributes: [:id, :verify_status])
    end

    private

    def changing_of_type?(type_de_champ)
      type_de_champ_update_params['type_champ'].present? && (type_de_champ_update_params['type_champ'] != type_de_champ.type_champ)
    end

    def champ_components_starting_at(coordinate, offset = 0)
      coordinate
        .siblings_starting_at(offset)
        .lazy
        .map { |c| champ_component_from(c) }
    end

    def champ_component_from(coordinate, focused: false, errors: '')
      TypesDeChampEditor::ChampComponent.new(
        coordinate:,
        upper_coordinates: coordinate.upper_coordinates,
        focused: focused,
        errors:
      )
    end

    def type_de_champ_create_params
      params
        .required(:type_de_champ)
        .permit(:type_champ, :parent_stable_id, :private, :libelle, :after_stable_id)
    end

    def type_de_champ_update_params
      params.required(:type_de_champ).permit(:type_champ,
        :libelle,
        :description,
        :mandatory,
        :drop_down_options_from_text,
        :drop_down_other,
        :drop_down_secondary_libelle,
        :drop_down_secondary_description,
        :drop_down_mode,
        :collapsible_explanation_enabled,
        :collapsible_explanation_text,
        :header_section_level,
        :positive_number,
        :min_number,
        :max_number,
        :range_number,
        :date_in_past,
        :range_date,
        :start_date,
        :end_date,
        :character_limit,
        :formatted_mode,
        :numbers_accepted,
        :letters_accepted,
        :special_characters_accepted,
        :min_character_length,
        :max_character_length,
        :expression_reguliere,
        :expression_reguliere_indications,
        :expression_reguliere_exemple_text,
        :expression_reguliere_error_message,
        :nature,
        editable_options: [
          :cadastres,
          :unesco,
          :arretes_protection,
          :conservatoire_littoral,
          :reserves_chasse_faune_sauvage,
          :reserves_biologiques,
          :reserves_naturelles,
          :natura_2000,
          :zones_humides,
          :znieff
        ])
    end

    def draft
      @procedure.draft_revision
    end

    def reload_procedure_with_includes
      ProcedureRevisionPreloader.load_one(draft)
    end

    def referentiel_file
      params["referentiel_file"]
    end

    def marcel_content_type
      Marcel::MimeType.for(referentiel_file.read, name: referentiel_file.original_filename, declared_type: referentiel_file.content_type)
    end

    def load_suggestion(rule, revision)
     end

    def allowed_rule?(rule)
      rule.in?([LLM::LabelImprover::TOOL_NAME])
    end
  end
end
