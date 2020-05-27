RSpec.describe ProcedureHelper, type: :helper do
  let(:auto_archive_date) { Time.zone.local(2020, 8, 2, 12, 00) }
  let(:procedure) { create(:procedure, auto_archive_on: auto_archive_date) }

  subject { show_auto_archive(procedure) }

  it "displays the day before the auto archive date (to account for the '23h59' ending time)" do
    expect(subject).to eq "1 août 2020"
  end
end
