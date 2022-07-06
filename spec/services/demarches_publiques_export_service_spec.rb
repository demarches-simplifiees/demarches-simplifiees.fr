describe DemarchesPubliquesExportService do
  let(:procedure) { create(:procedure, :published, :with_service, :with_type_de_champ) }
  let!(:dossier) { create(:dossier, procedure: procedure) }
  let(:io) { StringIO.new }

  describe 'call' do
    it 'generate json for all closed procedures' do
      expected_result = {
        number: procedure.id,
        title: procedure.libelle,
        description: "Demande de subvention à l'intention des associations",
        service: {
          nom: procedure.service.nom,
          organisme: "organisme",
          typeOrganisme: "association"
        },
        cadreJuridique: "un cadre juridique important",
        deliberation: nil,
        datePublication: procedure.published_at.iso8601,
        dossiersCount: 1,
        revision: {
          champDescriptors: [
            {
              description: procedure.types_de_champ.first.description,
              label: procedure.types_de_champ.first.libelle,
              options: nil,
              required: false,
              type: "text",
              champDescriptors: nil
            }
          ]
        }
      }

      DemarchesPubliquesExportService.new(io).call
      expect(JSON.parse(io.string)[0]
        .deep_symbolize_keys)
        .to eq(expected_result)
    end
    it 'raises exception when procedure with bad data' do
      procedure.libelle = nil
      procedure.save(validate: false)

      expect { DemarchesPubliquesExportService.new(io).call }.to raise_error(DemarchesPubliquesExportService::Error)
    end
  end
end
