# frozen_string_literal: true

require 'csv'

describe ProcedureExportService::CsvExport do
  let(:procedure) { create(:procedure, :published, public_type_de_champs: [{ type: :text, libelle: "texte" }, { type: :phone, libelle: "tel" }]) }
  let(:dossier) { create(:dossier, :en_construction, procedure:) }

  subject(:rows) do
    io = StringIO.new
    described_class.new(procedure:, dossiers: procedure.dossiers, export_template: nil).write_to(io)
    CSV.parse(io.string, headers: true)
  end

  before do
    texte, tel = dossier.root_champs_public
    texte.update!(value: '=HYPERLINK("https://example.com","clic")')
    tel.update!(value: '+33 6 12 34 56 78')
  end

  it 'exports formulas as text and keeps plain numbers' do
    expect(rows.first['texte']).to eq(%q('=HYPERLINK("https://example.com","clic")))
    expect(rows.first['tel']).to eq('+33 6 12 34 56 78')
  end
end
