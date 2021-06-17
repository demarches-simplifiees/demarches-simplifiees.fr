describe Traitement do
  describe '#count_dossiers_termines_by_month' do
    let(:procedure) { create(:procedure, :published, groupe_instructeurs: [groupe_instructeurs]) }
    let(:groupe_instructeurs) { create(:groupe_instructeur) }

    before do
      create_dossier_for_month(procedure, 2021, 3)
      create_dossier_for_month(procedure, 2021, 3)
      create_dossier_for_month(procedure, 2021, 2)
    end

    subject do
      Timecop.freeze(Time.zone.local(2021, 3, 5)) do
        Traitement.count_dossiers_termines_by_month(groupe_instructeurs)
      end
    end

    it 'count dossiers_termines by month' do
      expect(count_for_month(subject, 3)).to eq 2
      expect(count_for_month(subject, 2)).to eq 1
    end

    it 'returns descending order by month' do
      expect(subject[0]["month"].to_date.month).to eq 3
      expect(subject[1]["month"].to_date.month).to eq 2
    end
  end

  private

  def count_for_month(count_dossiers_termines_by_month, month)
    count_dossiers_termines_by_month.find do |count_by_month|
      count_by_month["month"].to_date.month == month
    end["count"]
  end

  def create_dossier_for_month(procedure, year, month)
    Timecop.freeze(Time.zone.local(year, month, 5)) do
      create(:dossier, :accepte, :with_attestation, procedure: procedure)
    end
  end
end
