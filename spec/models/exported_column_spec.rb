# frozen_string_literal: true

describe ExportedColumn do
  let(:procedure) { create(:procedure_with_dossiers, types_de_champ_public:) }
  let(:types_de_champ_public) do
    [
      { type: :text, libelle: "Ca va ?", mandatory: true, stable_id: 1 }
    ]
  end

  it 'class exists' do
    ExportedColumn.new(libelle: "Ca va ?", column: procedure.find_column(label: "Ca va ?"))
  end
end
