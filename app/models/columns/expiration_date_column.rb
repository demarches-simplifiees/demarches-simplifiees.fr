# frozen_string_literal: true

class Columns::ExpirationDateColumn < Columns::DossierColumn
  def initialize(procedure_id:)
    super(
      procedure_id:,
      table: nil,
      column: nil,
      label: "Date d'expiration",
      type: :datetime,
      displayable: true,
      options_for_select: []
    )
  end

  def value(dossier) = dossier.expiration_date
end
