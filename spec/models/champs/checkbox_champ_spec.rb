describe Champs::CheckboxChamp do
  it_behaves_like "a boolean champ" do
    let(:boolean_champ) { Champs::CheckboxChamp.new(value: value) }
  end
end
