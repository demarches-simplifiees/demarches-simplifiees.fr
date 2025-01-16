class ViewableChamp::HeaderSectionsSummaryComponent < ApplicationComponent
  def initialize(dossier:, is_private:)
    @dossier = dossier
    @is_private = is_private
  end

  def header_sections
    @dossier.revision
      .types_de_champ_for(scope: @is_private ? :private : :public)
      .filter(&:header_section?)
      .map { @dossier.project_champ(_1, nil) } # row_id not needed, do not link to repetiion header_sections
  end

  def href(header_section) # used by viewable champs to anchor elements
    "##{header_section.input_group_id}"
  end
end
