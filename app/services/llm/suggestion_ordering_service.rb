# frozen_string_literal: true

class LLM::SuggestionOrderingService
  ADD_KEY = 'add'
  UPDATE_KEY = 'update'

  def self.ordered_structure_suggestions(llm_rule_suggestion)
    original = build_original_list(llm_rule_suggestion.procedure_revision)
    suggestion_by_kind = llm_rule_suggestion.llm_rule_suggestion_items.group_by(&:op_kind)

    inject_added_header_sections(original, suggestion_by_kind[ADD_KEY] || [])
    swap_updated_rtdc_position(original, suggestion_by_kind[UPDATE_KEY] || [])
    inject_repetition_children(llm_rule_suggestion, original)
  end

  def self.inject_repetition_children(llm_rule_suggestion, original)
    original.flat_map do |suggestion_or_prtdc|
      prtdc = nil
      if suggestion_or_prtdc.is_a?(LLMRuleSuggestionItem)
        prtdc = llm_rule_suggestion.procedure_revision
          .revision_types_de_champ
          .find { it.stable_id == suggestion_or_prtdc.payload['stable_id'] }
      else
        prtdc = suggestion_or_prtdc
      end

      if prtdc.nil? # suggestion had been added, no prtdc exists yet
        [suggestion_or_prtdc]
      elsif prtdc.repetition?
        [suggestion_or_prtdc] + prtdc.revision_types_de_champ
      else
        [suggestion_or_prtdc]
      end
    end
  end

  def self.build_original_list(revision)
    revision.revision_types_de_champ_public
      .to_a
  end

  def self.ordered_label_suggestions(llm_rule_suggestion)
    root_tdcs, children_tdcs = llm_rule_suggestion.llm_rule_suggestion_items
      .partition { |item| item.payload['parent_id'].nil? }
    children_by_parent_id = children_tdcs.group_by { |item| item.payload['parent_id'] }

    root_tdcs
      .sort_by { |item| item.payload['position'] }
      .flat_map do |root_item|
        [root_item] +
          (children_by_parent_id[root_item.payload['stable_id']] || []).sort_by { |item| item.payload['position'] }
      end
  end

  def self.find_index_after_stable_id(original, stable_id)
    original.index { |rtdc| rtdc.stable_id == stable_id }
  end

  def self.inject_added_header_sections(original, add_suggestions)
    add_suggestions.each do |item|
      if (index = insertion_index_for(item, original))
        original.insert(index, item)
      end
    end
  end

  def self.swap_updated_rtdc_position(original, update_suggestions)
    update_suggestions.each do |item|
      original.reject! { it.stable_id == item.payload['stable_id'] }
      if (index = insertion_index_for(item, original))
        original.insert(index, item)
      end
    end
  end

  def self.insertion_index_for(item, original)
    case item.payload['after_stable_id']
    in nil
      0
    in Integer => after_stable_id if after_stable_id.negative?
      # after_stable_id is for a newly added item
      index = original.index do |rtdc|
        rtdc.is_a?(LLMRuleSuggestionItem) && rtdc.payload['generated_stable_id'] == after_stable_id
      end
      index ? index + 1 : nil
    in Integer => after_stable_id if after_stable_id.positive?
      # after_stable_id is for an existing item
      index = find_index_after_stable_id(original, after_stable_id)
      index ? index + 1 : nil
    end
  end
end
