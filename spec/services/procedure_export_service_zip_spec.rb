describe ProcedureExportService do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative, libelle: 'pj' }, { type: :repetition, children: [{ type: :piece_justificative, libelle: 'repet_pj' }] }]) }
  let(:dossiers) { create_list(:dossier, 10, procedure: procedure) }
  let(:export_template) { create(:export_template, :enabled_pjs, groupe_instructeur: procedure.defaut_groupe_instructeur) }
  let(:service) { ProcedureExportService.new(procedure, procedure.dossiers, instructeur, export_template) }

  def pj_champ(d) = d.champs_public.find_by(type: 'Champs::PieceJustificativeChamp')
  def repetition(d) = d.champs.find_by(type: "Champs::RepetitionChamp")
  def attachments(champ) = champ.piece_justificative_file.attachments

  before do
    dossiers.each do |dossier|
      attach_file_to_champ(pj_champ(dossier))

      repetition(dossier).add_row(dossier.revision)
      attach_file_to_champ(repetition(dossier).champs.first)
      attach_file_to_champ(repetition(dossier).champs.first)

      repetition(dossier).add_row(dossier.revision)
      attach_file_to_champ(repetition(dossier).champs.second)
    end

    allow_any_instance_of(ActiveStorage::Attachment).to receive(:url).and_return("https://opengraph.githubassets.com/d0e7862b24d8026a3c03516d865b28151eb3859029c6c6c2e86605891fbdcd7a/socketry/async-io")
  end

  describe 'to_zip' do
    subject { service.to_zip }

    describe 'generate_dossiers_export' do
      context 'with export_template' do
        let(:dossier_exports) { PiecesJustificativesService.new(user_profile: instructeur, export_template:).generate_dossiers_export(Dossier.where(id: dossier)) }

        it 'returns a blob with custom filenames' do
          VCR.use_cassette('archive/new_file_to_get_200', allow_playback_repeats: true) do
            sql_count = 0

            callback = lambda { |*_args| sql_count += 1 }
            ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
              subject
            end
            expect(sql_count <= 62).to be_truthy

            dossier = dossiers.first

            File.write('tmp.zip', subject.download, mode: 'wb')
            File.open('tmp.zip') do |fd|
              files = ZipTricks::FileReader.read_zip_structure(io: fd)
              structure = [
                "export/",
                "export/dossier-#{dossier.id}/",
                "export/dossier-#{dossier.id}/export-#{dossier.id}.pdf",
                "export/dossier-#{dossier.id}/pj-#{dossier.id}-01.png",
                "export/dossier-#{dossier.id}/repet_pj-#{dossier.id}-01-01.png",
                "export/dossier-#{dossier.id}/repet_pj-#{dossier.id}-02-01.png",
                "export/dossier-#{dossier.id}/repet_pj-#{dossier.id}-01-02.png"
              ]

              expect(files.size).to eq(dossiers.count * 6 + 1)
              expect(structure - files.map(&:filename)).to be_empty
            end
            FileUtils.remove_entry_secure('tmp.zip')
          end
        end
      end
    end
  end

  def attach_file_to_champ(champ, safe = true)
    attach_file(champ.piece_justificative_file, safe)
  end

  def attach_file(attachable, safe = true)
    to_be_attached = {
      io: StringIO.new("toto"),
      filename: "toto.png", content_type: "image/png"
    }

    if safe
      to_be_attached[:metadata] = { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    end

    attachable.attach(to_be_attached)
  end
end
