# frozen_string_literal: true

class DossierTree::Builder
  class << self
    def procedure_tree(coordinates, procedure:)
      context = DossierTree::Context.new(procedure:, types_de_champ: build_types_de_champ(coordinates))
      DossierTree.new(context)
    end

    def dossier_trees(public_coordinates, private_coordinates, dossier:, stream: nil, profile: nil)
      data = build_data(dossier, stream || dossier.stream)
      public_types_de_champ = build_types_de_champ(public_coordinates)
      private_types_de_champ = build_types_de_champ(private_coordinates)
      context = DossierTree::Context.new(procedure: dossier.procedure, types_de_champ: public_types_de_champ, data:, profile:)
      public_tree = DossierTree.new(context)
      private_tree = DossierTree.new(context.with_types_de_champ(private_types_de_champ))
      [public_tree, private_tree]
    end

    private

    def build_types_de_champ(coordinates)
      root_coordinates, repeater_coordinates = coordinates.partition { _1.parent_id.nil? }
      repeater_coordinates = repeater_coordinates.group_by(&:parent_id).transform_values { _1.sort_by(&:position) }
      coordinates = root_coordinates.flat_map { _1.repetition? ? [_1] + repeater_coordinates.fetch(_1.id, []) : _1 }

      ancestors = []
      parents = {}
      coordinates.each do |coordinate|
        parent = parents[coordinate] || coordinate.parent
        ancestor = ancestors.last
        repetition = ancestors.find { _1[:coordinate].repetition? }

        if repetition.present? && !parent&.repetition?
          # close repetition
          ancestors = ancestors.take_while { !_1[:coordinate].repetition? }
          ancestor = ancestors.last
          repetition = nil
        end

        if coordinate.header_section?
          # close section
          base_level = repetition ? repetition[:depth] : 0
          while ancestor.present? && ancestor[:depth] >= base_level + coordinate.header_section_level_value
            ancestors.pop
            ancestor = ancestors.last
          end
        end

        if ancestor.present?
          parents[coordinate] = ancestor[:coordinate]
        end

        if coordinate.header_section? || coordinate.repetition?
          ancestors << { coordinate:, depth: ancestors.size + 1 }
        end
      end

      coordinates
        .group_by { parents[_1]&.stable_id }
        .transform_values { _1.sort_by(&:position).map(&:type_de_champ) }
    end

    def build_data(dossier, stream)
      return if dossier.nil?

      rows, champs = champs_on_stream(dossier, stream).partition(&:row?)
      champs_data = champs.index_by(&:public_id)
      rows_data = rows.reject(&:discarded?)
        .group_by { _1.stable_id.to_s }
        .transform_values { _1.map(&:row_id).sort }

      champs_data.merge(rows_data)
    end

    def champs_on_stream(dossier, stream)
      case stream
      when ::Champ::USER_BUFFER_STREAM
        (champs_on_user_buffer_stream(dossier) + champs_on_main_stream(dossier)).uniq(&:public_id)
      else
        champs_on_main_stream(dossier)
      end
    end

    def champs_on_main_stream(dossier)
      dossier.champs.filter(&:main_stream?)
    end

    def champs_on_user_buffer_stream(dossier)
      dossier.champs.filter(&:user_buffer_stream?)
    end
  end
end
