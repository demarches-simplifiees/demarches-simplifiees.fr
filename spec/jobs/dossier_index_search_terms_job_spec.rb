RSpec.describe DossierIndexSearchTermsJob, type: :job do
  let(:dossier) { create(:dossier) }

  subject(:perform_job) { described_class.perform_now(dossier.reload) }

  before do
    create(:champ_text, dossier:, value: "un nouveau champ")
    create(:champ_text, dossier:, value: "private champ", private: true)
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
