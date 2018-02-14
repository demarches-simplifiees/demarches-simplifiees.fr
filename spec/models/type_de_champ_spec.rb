require 'spec_helper'

describe TypeDeChamp do
  require 'models/type_de_champ_shared_example'

  it_should_behave_like "type_de_champ_spec"

  describe '#public_only' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }

    it 'partition public and private' do
      expect(procedure.types_de_champ.count).to eq(1)
      expect(procedure.types_de_champ_private.count).to eq(1)
    end
  end
end
