RSpec.describe 'shared/archives/_table.html.haml', type: :view do
  include Rails.application.routes.url_helpers

  let(:procedure) { create(:procedure) }
  let(:all_archives) { create_list(:archive, 2) }
  let(:month_date) { "2022-01-01T00:00:00+00:00" }
  let(:average_dossier_weight) { 1024 }

  before do
      allow(view).to receive(:create_archive_url).and_return("/archive/created/stubed")
    end

  subject { render 'shared/archives/table.html.haml', count_dossiers_termines_by_month: [{ "month" => month_date, "count" => 5 }], archives: all_archives + [monthly_archive].compact, average_dossier_weight: average_dossier_weight, procedure: procedure }

  context "when archive is available" do
    let(:monthly_archive) { create(:archive, time_span_type: "monthly", month: month_date, job_status: :generated, file: Rack::Test::UploadedFile.new('spec/fixtures/files/RIB.pdf', 'application/pdf')) }
    it 'renders archive by month with estimate_weight' do
      expect(subject).to have_text("Janvier 2022")
      expect(subject).to have_text("Télécharger")
      expect(subject).to have_text("338 ko")
    end
  end

  context "when archive is not available" do
    let(:monthly_archive) { nil }
    it 'renders archive a estimated weight' do
      expect(subject).to have_text("Janvier 2022")
      expect(subject).to have_text("Demander")
      expect(subject).to have_text("5 ko")
    end

    context "when there are no weight estimation" do
      let(:average_dossier_weight) { nil }
      it 'supports an empty estimation weight' do
        expect(subject).to have_text("Demander")
      end
    end

    context "when estimation is too heavy" do
      let(:average_dossier_weight) { Archive::MAX_SIZE + 1 }
      it 'supports an empty estimation weight' do
        expect(subject).to have_text("trop volumineuse")
      end
    end
  end
end
