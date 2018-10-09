module Tasks
  class DossierProcedureMigrator
    # Migrates dossiers from an old source procedure to a revised destination procedure.

    class ChampMapping
      def initialize(source_procedure, destination_procedure)
        @source_procedure = source_procedure
        @destination_procedure = destination_procedure

        @expected_source_types_de_champ = {}
        @expected_destination_types_de_champ = {}
        @source_to_destination_mapping = {}
        @source_champs_to_discard = Set[]
        @destination_champ_computations = []
      end

      def check_source_destination_champs_consistency
        check_champs_consistency('source', @expected_source_types_de_champ, @source_procedure.types_de_champ)
        check_champs_consistency('destination', @expected_destination_types_de_champ, @destination_procedure.types_de_champ)
      end

      def migrate_champs(dossier)
        # Since we’re going to iterate and change the champs at the same time,
        # we use to_a to make the list static and avoid nasty surprises
        original_champs = dossier.champs.to_a

        compute_new_champs(dossier)

        original_champs.each do |c|
          tdc_to = destination_type_de_champ(c)
          if tdc_to.present?
            c.update(type_de_champ: tdc_to)
          elsif discard_champ?(c)
            dossier.champs.destroy(c)
          else
            fail "Unhandled source type de champ #{c.type_de_champ.order_place}"
          end
        end
      end

      private

      def compute_new_champs(dossier)
        @destination_champ_computations.each do |tdc, block|
          dossier.champs << block.call(dossier, tdc)
        end
      end

      def destination_type_de_champ(champ)
        @source_to_destination_mapping[champ.type_de_champ.order_place]
      end

      def discard_champ?(champ)
        @source_champs_to_discard.member?(champ.type_de_champ.order_place)
      end

      def check_champs_consistency(label, expected_tdcs, actual_tdcs)
        if actual_tdcs.size != expected_tdcs.size
          raise "Incorrect #{label} size #{actual_tdcs.size} (expected #{expected_tdcs.size})"
        end
        actual_tdcs.each { |tdc| check_champ_consistency(label, expected_tdcs[tdc.order_place], tdc) }
      end

      def check_champ_consistency(label, expected_tdc, actual_tdc)
        errors = []
        if actual_tdc.libelle != expected_tdc['libelle']
          errors.append("incorrect libelle #{actual_tdc.libelle} (expected #{expected_tdc['libelle']})")
        end
        if actual_tdc.type_champ != expected_tdc['type_champ']
          errors.append("incorrect type champ #{actual_tdc.type_champ} (expected #{expected_tdc['type_champ']})")
        end
        if (!actual_tdc.mandatory) && expected_tdc['mandatory']
          errors.append("champ should be mandatory")
        end
        drop_down = actual_tdc.drop_down_list.presence&.options&.presence
        if drop_down != expected_tdc['drop_down']
          errors.append("incorrect drop down list #{drop_down} (expected #{expected_tdc['drop_down']})")
        end
        if errors.present?
          fail "On #{label} type de champ #{actual_tdc.order_place} (#{actual_tdc.libelle}) " + errors.join(', ')
        end
      end

      def map_source_to_destination_champ(source_order_place, destination_order_place, source_overrides: {}, destination_overrides: {})
        destination_type_de_champ = @destination_procedure.types_de_champ.find_by(order_place: destination_order_place)
        @expected_source_types_de_champ[source_order_place] =
          type_de_champ_to_expectation(destination_type_de_champ)
          .merge!(source_overrides)
        @expected_destination_types_de_champ[destination_order_place] =
          type_de_champ_to_expectation(@source_procedure.types_de_champ.find_by(order_place: source_order_place))
          .merge!({ "mandatory" => false }) # Even if the source was mandatory, it’s ok for the destination to be optional
          .merge!(destination_overrides)
        @source_to_destination_mapping[source_order_place] = destination_type_de_champ
      end

      def discard_source_champ(source_type_de_champ)
        @expected_source_types_de_champ[source_type_de_champ.order_place] = type_de_champ_to_expectation(source_type_de_champ)
        @source_champs_to_discard << source_type_de_champ.order_place
      end

      def compute_destination_champ(destination_type_de_champ, &block)
        @expected_destination_types_de_champ[destination_type_de_champ.order_place] = type_de_champ_to_expectation(destination_type_de_champ)
        @destination_champ_computations << [@destination_procedure.types_de_champ.find_by(order_place: destination_type_de_champ.order_place), block]
      end

      def type_de_champ_to_expectation(tdc)
        if tdc.present?
          expectation = tdc.as_json(only: [:libelle, :type_champ, :mandatory])
          expectation['drop_down'] = tdc.drop_down_list.presence&.options&.presence
          expectation
        else
          {}
        end
      end
    end

    def initialize(source_procedure, destination_procedure, champ_mapping)
      @source_procedure = source_procedure
      @destination_procedure = destination_procedure
      @champ_mapping = champ_mapping
    end

    def migrate_procedure
      check_consistency
      migrate_dossiers
      migrate_gestionnaires
      publish_destination_procedure_in_place_of_source
    end

    def check_consistency
      check_same_administrateur
      @champ_mapping.check_source_destination_champs_consistency
    end

    def check_same_administrateur
      if @source_procedure.administrateur != @destination_procedure.administrateur
        raise "Mismatching administrateurs #{@source_procedure.administrateur&.email} → #{@destination_procedure.administrateur&.email}"
      end
    end

    def migrate_dossiers
      @source_procedure.dossiers.find_each(batch_size: 100) do |d|
        @champ_mapping.migrate_champs(d)

        # Use update_columns to avoid triggering build_default_champs
        d.update_columns(procedure_id: @destination_procedure.id)
      end
    end

    def migrate_gestionnaires
      @source_procedure.gestionnaires.find_each(batch_size: 100) { |g| g.assign_to_procedure(@destination_procedure) }
    end

    def publish_destination_procedure_in_place_of_source
      @destination_procedure.publish!(@source_procedure.path)
      @source_procedure.archive
    end
  end
end
