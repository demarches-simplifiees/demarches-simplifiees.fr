describe Zone do
  let(:now) { Time.zone.parse("2022-08-11") }
  before do
    Timecop.freeze(now)
  end

  after do
    Timecop.return
  end

  describe '#label' do
    let(:start_previous_government) { Date.parse('2020-07-06') }
    let(:start_last_government) { Date.parse('2022-05-20') }
    let(:zone) do
      create(:zone, labels: [
        {
          designated_on: start_previous_government,
          name: "Ministère de l'Économie, des Finances et de la Relance"
        },
        {
          designated_on: start_last_government,
          name: "Ministère de l'Économie, des Finances et de la Souveraineté industrielle et numérique"
        }
      ])
    end

    it 'returns label for the current millesime' do
      expect(zone.label).to eq "Ministère de l'Économie, des Finances et de la Souveraineté industrielle et numérique"
    end

    it 'returns label at specific date' do
      expect(zone.label_at(start_previous_government + 1.week)).to eq "Ministère de l'Économie, des Finances et de la Relance"
      expect(zone.label_at(start_last_government + 1.week)).to eq "Ministère de l'Économie, des Finances et de la Souveraineté industrielle et numérique"
      expect(zone.label_at(start_previous_government - 1.week)).to eq "Ministère de l'Économie, des Finances et de la Relance"
    end
  end
end

