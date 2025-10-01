# frozen_string_literal: true

class LLM::SuggestionItemComponent < ApplicationComponent
  attr_reader :form_builder

  def initialize(form_builder:)
    @form_builder = form_builder
  end

  def item
    form_builder.object
  end

  def llm_rule_suggestion
    item.llm_rule_suggestion
  end

  def revision
    llm_rule_suggestion.procedure_revision
  end

  def procedure
    revision.procedure
  end

  def tdc_for(stable_id)
    prtdc_index[stable_id]&.type_de_champ
  end

  def position_for(stable_id)
    prtdc_index[stable_id]&.position
  end

  def prtdc_index
    @prtdc_index ||= revision.revision_types_de_champ_public.index_by(&:stable_id)
  end
end
