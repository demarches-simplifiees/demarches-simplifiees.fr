RSpec.describe DossierIndexSearchTermsJob, type: :job do
  let(:procedure) { create(:procedure, :published, types_de_champ_public:, types_de_champ_private:) }
  let(:types_de_champ_public) { [{ type: :text }] }
  let(:types_de_champ_private) { [{ type: :text }] }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ_siret) { dossier.champs.first }

  subject(:perform_job) { described_class.perform_now(dossier.reload) }

  before do
    dossier.champs_public.first.update_column(:value, "un nouveau champ")
    dossier.champs_private.first.update_column(:value, "private champ")
  end

  it "update search terms columns" do
    perform_job

    sql = "SELECT search_terms, private_search_terms FROM dossiers WHERE id = :id"
    sanitized_sql = Dossier.sanitize_sql_array([sql, id: dossier.id])
    result = Dossier.connection.execute(sanitized_sql).first

    expect(result['search_terms']).to match(/un nouveau champ/)
    expect(result['private_search_terms']).to match(/private champ/)
  end
end
