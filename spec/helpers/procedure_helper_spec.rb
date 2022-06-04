RSpec.describe ProcedureHelper, type: :helper do
  describe '#procedure_auto_archive_datetime' do
    let(:auto_archive_date) { Time.zone.local(2020, 8, 2, 12, 00) }
    let(:procedure) { build(:procedure, auto_archive_on: auto_archive_date) }

    subject { procedure_auto_archive_datetime(procedure) }

    it "displays the day before the auto archive date (to account for the '23h59' ending time)" do
      expect(subject).to have_text("1 août 2020 à 23 h 59 (heure de Tahiti)")
    end
  end

  describe '#estimated_fill_duration_minutes' do
    subject { estimated_fill_duration_minutes(procedure) }

    context 'with champs' do
      let(:procedure) { build(:procedure, :with_yes_no, :with_piece_justificative) }

      it 'rounds up the duration to the minute' do
        expect(subject).to eq(2)
      end
    end

    context 'without champs' do
      let(:procedure) { build(:procedure) }

      it 'never displays ‘zero minutes’' do
        expect(subject).to eq(1)
      end
    end
  end
end
