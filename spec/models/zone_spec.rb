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
      expect(zone.current_label).to eq "Ministère de l'Économie, des Finances et de la Souveraineté industrielle et numérique"
    end

    it 'returns label at specific date' do
      expect(zone.label_at(start_previous_government + 1.week)).to eq "Ministère de l'Économie, des Finances et de la Relance"
      expect(zone.label_at(start_last_government + 1.week)).to eq "Ministère de l'Économie, des Finances et de la Souveraineté industrielle et numérique"
      expect(zone.label_at(start_previous_government - 1.week)).to eq "Ministère de l'Économie, des Finances et de la Relance"
    end
  end

  describe "#available_at?" do
    let(:start_previous_government) { Date.parse('2020-07-06') }
    let(:start_last_government) { Date.parse('2022-05-20') }
    let(:start_futur_government) { Date.parse('2027-05-20') }
    let(:zone) do
      create(:zone, labels: [
        {
          designated_on: start_previous_government,
          name: "Ministère des Outre-mer"
        },
        {
          designated_on: start_last_government,
          name: "Non attribué"
        },
        {
          designated_on: start_futur_government,
          name: "Ministère des Territoires d'Outre-mer"
        }
      ])
    end

    it "returns false if the zone does'nt exist at a specific date" do
      expect(zone.available_at?(start_last_government + 1.week)).to be_falsy
    end

    it "returns true if the zone exist at a specific date" do
      expect(zone.available_at?(start_futur_government + 1.week)).to be_truthy
      expect(zone.available_at?(start_previous_government + 1.week)).to be_truthy
    end
  end

  describe "#self.available_at?" do
    let(:start_previous_government) { Date.parse('2020-07-06') }
    let(:start_last_government) { Date.parse('2022-05-20') }
    let(:start_futur_government) { Date.parse('2027-05-20') }
    let(:om) do
      create(:zone, labels: [
        {
          designated_on: start_previous_government,
          name: "Ministère des Outre-mer"
        },
        {
          designated_on: start_last_government,
          name: "Non attribué"
        },
        {
          designated_on: start_futur_government,
          name: "Ministère des Territoires d'Outre-mer"
        }
      ])
    end

    let!(:culture) do
      create(:zone, labels: [
        {
          designated_on: start_previous_government,
          name: "Ministère de la Culture"
        }
      ])
    end

    let!(:om) do
      create(:zone, labels: [
        {
          designated_on: start_previous_government,
          name: "Ministère des Outre-mer"
        },
        {
          designated_on: start_last_government,
          name: "Non attribué"
        },
        {
          designated_on: start_futur_government,
          name: "Ministère des Territoires d'Outre-mer"
        }
      ])
    end

    it 'returns only available zones at specific date' do
      expect(Zone.available_at(start_last_government + 1.day).map(&:label)).to eq ["Ministère de la Culture"]
      expect(Zone.available_at(start_previous_government + 1.day).map(&:label)).to eq ["Ministère de la Culture", "Ministère des Outre-mer"]
    end
  end
end
