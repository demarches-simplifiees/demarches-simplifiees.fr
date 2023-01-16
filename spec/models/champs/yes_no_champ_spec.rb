describe Champs::YesNoChamp do
  it_behaves_like "a boolean champ" do
    let(:boolean_champ) { Champs::YesNoChamp.new(value: value) }
  end
end
