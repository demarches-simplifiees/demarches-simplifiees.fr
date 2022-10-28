describe DemarchesPubliquesExportService do
  let(:procedure) { create(:procedure, :published, :with_service, :with_type_de_champ) }
  let!(:dossier) { create(:dossier, procedure: procedure) }
  let(:gzip_filename) { "demarches.json.gz" }

  after { FileUtils.rm(gzip_filename) }

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
      DemarchesPubliquesExportService.new(gzip_filename).call

      expect(JSON.parse(deflat_gzip(gzip_filename))[0]
        .deep_symbolize_keys)
        .to eq(expected_result)
    end

    it 'raises exception when procedure with bad data' do
      procedure.libelle = nil
      procedure.save(validate: false)

      expect { DemarchesPubliquesExportService.new(gzip_filename).call }.to raise_error(DemarchesPubliquesExportService::Error)
    end
  end

  def deflat_gzip(gzip_filename)
    Zlib::GzipReader.open(gzip_filename) do |gz|
      return gz.read
    end
  end
end
