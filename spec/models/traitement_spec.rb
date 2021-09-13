describe Traitement do
  let(:procedure) { create(:procedure, :published, groupe_instructeurs: [groupe_instructeurs]) }
  let(:groupe_instructeurs) { create(:groupe_instructeur) }

  describe '#count_dossiers_termines_by_month' do
    before do
      create_dossier_for_month(procedure, 2021, 3)
      create_dossier_for_month(procedure, 2021, 3)
      create_archived_dossier_for_day(procedure, 2021, 3, 1)
      create_dossier_for_month(procedure, 2021, 2)
    end

    subject do
      Timecop.freeze(Time.zone.local(2021, 3, 5)) do
        Traitement.count_dossiers_termines_by_month(groupe_instructeurs)
      end
    end

    it 'count dossiers_termines by month' do
      expect(count_for_month(subject, 3)).to eq 3
      expect(count_for_month(subject, 2)).to eq 1
    end

    it 'returns descending order by month' do
      expect(subject[0]["month"].to_date.month).to eq 3
      expect(subject[1]["month"].to_date.month).to eq 2
    end
  end

  describe '#count_dossiers_termines_by_days_for_month' do
    let(:month) { parse("2021-04-01") }

    before do
      create_dossier_for_day(procedure, 2021, 4, 2)
      create_dossier_for_day(procedure, 2021, 4, 2)
      create_dossier_for_day(procedure, 2021, 4, 3)
      create_dossier_for_day(procedure, 2021, 4, 4)
      create_dossier_for_day(procedure, 2021, 4, 5)
      create_archived_dossier_for_day(procedure, 2021, 4, 5)
      create_dossier_for_month(procedure, 2021, 2)
    end

    subject do
      Traitement.count_dossiers_termines_by_days_for_month(groupe_instructeurs, month)
    end

    it 'count dossiers_termines by day for a month' do
      expect(subject.to_a).to eq [
        { "day" => parse("2021-04-05"), "count" => 2 },
        { "day" => parse("2021-04-04"), "count" => 1 },
        { "day" => parse("2021-04-03"), "count" => 1 },
        { "day" => parse("2021-04-02"), "count" => 2 }
      ]
    end
  end

  describe "count_dossiers_termines_with_archive_size_limit" do
    let(:month) { parse("2021-04-01") }

    before do
      create_dossier_for_day(procedure, 2021, 4, 2)
      create_dossier_for_day(procedure, 2021, 4, 2)
      create_dossier_for_day(procedure, 2021, 4, 3)
      create_dossier_for_day(procedure, 2021, 4, 4)
      create_dossier_for_day(procedure, 2021, 4, 5)
    end

    subject do
      Traitement.count_dossiers_termines_with_archive_size_limit(procedure, groupe_instructeurs, month)
    end
    it 'splits when archive too big' do
      allow_any_instance_of(Procedure).to receive(:average_dossier_weight).and_return(2.gigabyte)

      expect(subject.to_a).to eq [{ start_day: parse("2021-04-05"), end_day: parse("2021-04-04"), count: 2 }, { start_day: parse("2021-04-03"), end_day: parse("2021-04-02"), count: 3 }]
    end
  end

  private

  def parse(date)
    Time.find_zone("UTC").parse(date)
  end

  def count_for_month(count_dossiers_termines_by_month, month)
    count_dossiers_termines_by_month.find do |count_by_month|
      count_by_month["month"].to_date.month == month
    end["count"]
  end

  def create_dossier_for_month(procedure, year, month)
    create_dossier_for_day(procedure, year, month, 5)
  end

  def create_dossier_for_day(procedure, year, month, day)
    Timecop.freeze(Time.zone.local(year, month, day)) do
      create(:dossier, :accepte, :with_attestation, procedure: procedure)
    end
  end

  def create_archived_dossier_for_day(procedure, year, month, day)
    Timecop.freeze(Time.zone.local(year, month, day)) do
      create(:dossier, :accepte, :archived, :with_attestation, procedure: procedure)
    end
  end
end
