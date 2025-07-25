# frozen_string_literal: true

class DossierTree
  include ActiveModel::Validations

  attr_reader :children

  def initialize(context)
    @context = context
    @children = context.children(nil, [])
  end

  validates_each :champs do |record, _, champs|
    champs.filter(&:visible?).each do |champ|
      champ.validate(record.validation_context)
      champ.errors.each { record.errors.import(_1) }
    end
  end

  def champs = children.flat_map(&:champs)
  def repeaters = children.flat_map(&:repeaters)
  def sections = children.flat_map(&:sections)
  def flatten = children.flat_map(&:flatten)

  def self.build(coordinates:, procedure:, dossier: nil, stream: nil, profile: nil)
    context = DossierTree::Context.new(procedure:, profile:,
      types_de_champ: types_de_champ(coordinates),
      data: data(dossier, stream))
    new(context)
  end

  def with_coordinates(coordinates)
    types_de_champ = self.class.types_de_champ(coordinates)
    context = @context.with_types_de_champ(types_de_champ)
    self.class.new(context)
  end

  class << self
    def types_de_champ(coordinates)
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

    private

    def data(dossier, stream)
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
