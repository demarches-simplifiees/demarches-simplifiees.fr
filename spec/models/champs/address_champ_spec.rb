describe Champs::AddressChamp do
  let(:champ) { Champs::AddressChamp.new(value: value, data: data, type_de_champ: create(:type_de_champ_address)) }
  let(:value) { '' }
  let(:data) { nil }

  context "with value but no data" do
    let(:value) { 'Paris' }

    it { expect(champ.address_label).to eq('Paris') }
    it { expect(champ.full_address?).to be_falsey }
  end

  context "with value and data" do
    let(:value) { '33 Rue Rébeval 75019 Paris' }
    let(:data) do
      {
        "type" => "housenumber",
        "label" => "33 Rue Rébeval 75019 Paris",
        "city_code" => "75119",
        "city_name" => "Paris",
        "postal_code" => "75019",
        "region_code" => "11",
        "region_name" => "Île-de-France",
        "street_name" => "Rue Rébeval",
        "street_number" => "33",
        "street_address" => "33 Rue Rébeval",
        "department_code" => "75",
        "department_name" => "Paris"
      }
    end

    it { expect(champ.address_label).to eq('33 Rue Rébeval 75019 Paris') }
    it { expect(champ.full_address?).to be_truthy }
    it { expect(champ.commune).to eq({ name: 'Paris 19e Arrondissement', code: '75119', postal_code: '75019' }) }
  end

  context "with wrong code INSEE" do
    let(:value) { 'Rue du Bois Charles 27700 Les Trois Lacs' }
    let(:data) do
      {
        "type" => "housenumber",
        "label" => "Rue du Bois Charles 27700 Les Trois Lacs",
        "city_code" => "27058",
        "city_name" => "Les Trois Lacs",
        "postal_code" => "27700",
        "department_code" => "27",
        "department_name" => "Eure"
      }
    end

    it { expect(champ.address_label).to eq('Rue du Bois Charles 27700 Les Trois Lacs') }
    it { expect(champ.full_address?).to be_truthy }
    it { expect(champ.commune).to eq({ name: 'Les Trois Lacs', code: '27676', postal_code: '27700' }) }
  end
end
