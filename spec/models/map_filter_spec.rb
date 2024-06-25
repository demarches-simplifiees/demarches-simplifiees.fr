describe MapFilter do
  let(:map_filter) do
    mf = MapFilter.new(params)
    mf.stats = { '63' => { nb_demarches: 51, nb_dossiers: 2001 } }
    mf
  end

  describe 'css_class_for_departement' do
    let(:params) { { kind: "nb_demarches" } }
    context 'for nb_demarches' do
      it 'return class css' do
        expect(map_filter.css_class_for_departement('63')).to eq :medium
      end
    end

    context 'fr nb_dossiers' do
      let(:params) { { kind: "nb_dossiers" } }
      it 'return class css' do
        expect(map_filter.css_class_for_departement('63')).to eq :medium
      end
    end
  end
end
