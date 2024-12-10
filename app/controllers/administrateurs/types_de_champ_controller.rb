# frozen_string_literal: true

module Administrateurs
  class TypesDeChampController < AdministrateurController
    include ActiveSupport::NumberHelper

    before_action :retrieve_procedure
    after_action :reset_procedure, only: [:create, :update, :destroy, :piece_justificative_template]
    before_action :reload_procedure_with_includes, only: [:destroy]

    CSV_MAX_SIZE = 1.megabyte
    CSV_ACCEPTED_CONTENT_TYPES = [
      "text/csv",
      "application/vnd.ms-excel"
    ]

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
        @morphed = @morphed.where("position > ?", to).where(position: ..from)
      else # case of moved down, update components from origin up to target (< minus one)
        @morphed = @morphed.where(position: from..).where(position: ...to)
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
      if !CSV_ACCEPTED_CONTENT_TYPES.include?(referentiel_file.content_type) && !CSV_ACCEPTED_CONTENT_TYPES.include?(marcel_content_type)
        flash[:alert] = "Importation impossible : veuillez importer un fichier CSV"

      elsif referentiel_file.size > CSV_MAX_SIZE
        flash[:alert] = "Importation impossible : le poids du fichier est supérieur à #{number_to_human_size(CSV_MAX_SIZE)}"

      else
        file = referentiel_file.read
        return flash[:alert] = "Importation impossible : votre fichier CSV est vide" if file.blank?

        base_encoding = CharlockHolmes::EncodingDetector.detect(file)

        type_de_champ = draft.find_and_ensure_exclusive_use(params[:stable_id])

        csv_to_code = ACSV::CSV.new_for_ruby3(file.encode("UTF-8", base_encoding[:encoding], invalid: :replace, replace: ""), headers: true).map(&:to_h)

        headers = csv_to_code.first.keys

        ActiveRecord::Base.transaction do
          # Create referentiel
          referentiel = type_de_champ.create_referentiel!(name: referentiel_file.original_filename, headers:)

          # Create referentiel items
          # We add headers to items in order to display them in instructeur view
          # even if the referentiel has been deleted
          items_to_insert = csv_to_code.map do |row|
            {
              data: {
                row: row.transform_keys { |k| k.parameterize.underscore }
              },
              referentiel_id: referentiel.id
            }
          end

          ReferentielItem.insert_all(items_to_insert)
        end
        @coordinate = draft.coordinate_for(type_de_champ)
        @morphed = [champ_component_from(@coordinate)]
      end
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
        :character_limit,
        :expression_reguliere,
        :expression_reguliere_exemple_text,
        :expression_reguliere_error_message,
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
  end
end
