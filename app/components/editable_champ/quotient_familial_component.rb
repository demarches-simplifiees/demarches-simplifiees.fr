# frozen_string_literal: true

class EditableChamp::QuotientFamilialComponent < EditableChamp::EditableChampBaseComponent
  delegate :not_recovered_qf_data?, :recovered_qf_data?, :correct_qf_data?, :incorrect_qf_data?, to: :@champ

  def initialize(form:, champ:, seen_at: nil, aria_labelledby_prefix: nil, row_number: nil)
    super
    @dossier = champ.dossier
    @type_de_champ = champ.type_de_champ
    @substitution_tdc = @dossier.revision.children_of(@type_de_champ).first
  end

  def for_preview?
    @champ.dossier.for_procedure_preview?
  end

  def qf_data
    if for_preview?
      JSON.parse(
        File.read(
          File.join(__dir__, "quotient_familial_component", "preview_quotient_familial_data.json")
        )
      )
    end
  end

  def render_automatic_qf_tdc?
    recovered_qf_data?
  end

  def render_substitution_qf_tdc?
    not_recovered_qf_data? || (recovered_qf_data? && incorrect_qf_data?)
  end

  private

  def substitution_champ_component
    EditableChamp::EditableChampComponent.new(form: @form, champ: @dossier.project_champ(@substitution_tdc))
  end
end
