# frozen_string_literal: true

describe '20240920130741_migrate_procedure_presentation_to_columns.rake' do
  let(:rake_task) { Rake::Task['after_party:migrate_procedure_presentation_to_columns'] }

  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :text }]) }
  let(:instructeur) { create(:instructeur) }
  let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: instructeur) }
  let(:stable_id) { procedure.active_revision.types_de_champ.first.stable_id }
  let!(:procedure_presentation) do
    displayed_fields = [
      { "table" => "etablissement", "column" => "entreprise_raison_sociale" },
      { "table" => "type_de_champ", "column" => stable_id.to_s }
    ]

    sort = { "order" => "desc", "table" => "self", "column" => "en_construction_at" }

    filters = {
      "tous" => [],
       "suivis" => [],
       "traites" => [{ "label" => "Libellé NAF", "table" => "etablissement", "value" => "Administration publique générale", "column" => "libelle_naf", "value_column" => "value" }],
       "a-suivre" => [],
       "archives" => [],
       "expirant" => [],
       "supprimes" => [],
       "supprimes_recemment" => []
    }

    create(:procedure_presentation, assign_to:, displayed_fields:, filters:, sort:)
  end

  before do
    rake_task.invoke

    procedure_presentation.reload
  end

  it 'populates the columns' do
    procedure_id = procedure.id

    expect(procedure_presentation.displayed_columns.map(&:label)).to eq(["Raison sociale", procedure.active_revision.types_de_champ.first.libelle])

    order, column_id = procedure_presentation
      .sorted_column
      .then { |sorted| [sorted.order, sorted.column.h_id] }

    expect(order).to eq('desc')
    expect(column_id).to eq(procedure_id: procedure_id, column_id: "self/en_construction_at")

    expect(procedure_presentation.tous_filters).to eq([])

    traites = procedure_presentation.traites_filters.map { [_1.label, _1.filter] }

    expect(traites).to eq([["Libellé NAF", "Administration publique générale"]])
  end
end
