# frozen_string_literal: true

describe TypesDeChamp::CommuneTypeDeChamp do
  let(:subject) { create(:type_de_champ_communes, libelle: 'Ma commune') }

  it { expect(subject.libelles_for_export).to match_array([['Ma commune', :value, ""], ['Ma commune (Code INSEE)', :code, ""], ['Ma commune (Département)', :departement, ""]]) }
end
