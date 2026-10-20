# frozen_string_literal: true

# Request spec (full Rack stack) because #telecharger_pjs streams the zip via
# zip_kit. Controller specs no longer materialize a streamed Rack body under
# Rails 8, so the streamed bytes must be asserted at the request level.
describe "Instructeurs::DossiersController#telecharger_pjs", type: :request do
  let(:procedure) { procedures.individual }
  let(:dossier) { dossiers.en_construction }

  before { login_as(instructeurs.default.user, scope: :user) }

  subject do
    get telecharger_pjs_instructeur_dossier_path(procedure_id: procedure.id, dossier_id: dossier.id)
    response
  end

  def zip_entry_names(body)
    ZipKit::FileReader.read_zip_structure(io: StringIO.new(body)).map(&:filename)
  end

  it 'includes an attachment' do
    expect(subject.headers['Content-Disposition']).to start_with('attachment; ')
  end

  it 'streams an extractable zip' do
    file_names = zip_entry_names(subject.body)

    expect(file_names.size).to eq(1)
    expect(file_names.first).to start_with("dossier-#{dossier.id}/export-")
  end

  context 'when an attachment is missing from the storage' do
    let(:procedure) { create(:procedure, :published, :for_individual, public_type_de_champs: [{ type: :piece_justificative }, { type: :piece_justificative }], instructeurs: [instructeurs.default]) }
    let(:dossier) { create(:dossier, :en_construction, :with_individual, :with_populated_champs, procedure:) }

    before do
      missing_blob, present_blob = dossier.champs.map { it.piece_justificative_file.first.blob }
      missing_blob.update!(filename: "missing.txt")
      missing_blob.service.delete(missing_blob.key)
      present_blob.update!(filename: "present.txt")
    end

    it 'streams a valid zip without it' do
      file_names = zip_entry_names(subject.body)

      expect(file_names.size).to eq(2)
      expect(file_names).to include(start_with("dossier-#{dossier.id}/export-"))
      expect(file_names).to include(start_with("dossier-#{dossier.id}/pieces_justificatives/present-"))
    end

    it 'leaves no local header of it, which sequential unzippers (macOS) choke on' do
      expect(subject.body).not_to include("pieces_justificatives/missing-")
    end
  end
end
