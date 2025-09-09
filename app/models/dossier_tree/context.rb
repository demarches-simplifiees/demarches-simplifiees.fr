# frozen_string_literal: true

class DossierTree::Context
  def initialize(procedure:, types_de_champ:, profile: nil, data: nil, row: nil, seen: [])
    @procedure = procedure
    @types_de_champ = types_de_champ
    @data = data
    @row = row
    @seen = seen.to_set
    @profile = profile
  end

  DEFAULT_ROW_ID = "01K4W68PJ15ZHASB3Y53NDZM77"
  def row_ids(type_de_champ)
    if @data.nil?
      [DEFAULT_ROW_ID]
    else
      @data.fetch(public_id(type_de_champ), [])
    end
  end

  def data(type_de_champ)
    @data&.fetch(public_id(type_de_champ), nil)
  end

  def seen(data)
    @seen.add(data)
  end

  def columns(type_de_champ)
    type_de_champ.columns(procedure: @procedure)
  end

  def public_id(type_de_champ)
    type_de_champ.public_id(row_id)
  end

  # TODO: remove when we don't need legacy identifiers anymore
  def html_id(type_de_champ)
    if @data.nil?
      coordinate = @procedure.draft_revision.coordinate_for(type_de_champ)
      ActionView::RecordIdentifier.dom_id(coordinate, :type_de_champ_editor)
    else
      "champ-#{public_id(type_de_champ)}"
    end
  end

  def with_row(row)
    DossierTree::Context.new(procedure: @procedure,
      types_de_champ: @types_de_champ,
      data: @data,
      seen: @seen.to_a,
      profile: @profile,
      row:)
  end

  def with_types_de_champ(types_de_champ)
    DossierTree::Context.new(procedure: @procedure,
      types_de_champ:,
      data: @data,
      seen: @seen.to_a,
      profile: @profile)
  end

  def children(parent_stable_id, ancestors)
    @types_de_champ.fetch(parent_stable_id, []).map do |type_de_champ|
      case type_de_champ.type_champ
      when 'repetition'
        raise "Repeater within repeater is not supported" if row?
        DossierTree::Repeater.new(type_de_champ, self, ancestors:)
      when 'header_section'
        DossierTree::Section.new(type_de_champ, self, ancestors:)
      when 'explication'
        DossierTree::Explication.new(type_de_champ, self, ancestors:)
      else
        DossierTree::Champ.new(type_de_champ, self, ancestors:)
      end
    end
  end

  def visible?(type_de_champ, ancestors, blank: false)
    return true if @data.nil?
    return false if ancestors.any? { _1.class == DossierTree::Repeater::Row && !_1.visible? }

    if type_de_champ.read_attribute_before_type_cast('condition').present?
      visible = type_de_champ.condition.compute(@seen.to_a)
      if !visible && type_de_champ.public? && ['instructeur', 'expert'].include?(@profile) && !blank
        true
      else
        visible
      end
    else
      true
    end
  end

  private

  def row_id
    @row&.id
  end

  def row?
    !@row.nil?
  end
end
