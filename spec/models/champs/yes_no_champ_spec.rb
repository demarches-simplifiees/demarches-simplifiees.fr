describe Champs::YesNoChamp do
  it_behaves_like "a boolean champ" do
    let(:boolean_champ) { described_class.new(value: value) }
    before { allow(boolean_champ).to receive(:type_de_champ).and_return(build(:type_de_champ_yes_no)) }
  end
end
