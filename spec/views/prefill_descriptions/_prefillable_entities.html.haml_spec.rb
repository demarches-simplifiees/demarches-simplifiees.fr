# frozen_string_literal: true

describe 'prefill_descriptions/prefillable_entities.html.haml', type: :view do
  let(:prefill_description) { PrefillDescription.new(create(:procedure)) }
  let!(:type_de_champ) { create(:type_de_champ_drop_down_list, procedure: prefill_description, drop_down_options: options) }

  subject { render('prefill_descriptions/prefillable_entities', prefill_description: prefill_description) }

  context 'when a type de champ has too many values' do
    let(:options) { (1..20).map(&:to_s) }

    it { is_expected.to have_content(type_de_champ.libelle) }

    it { is_expected.to have_link(text: "Voir toutes les valeurs possibles", href: prefill_type_de_champ_path(prefill_description.path, type_de_champ)) }
  end

  context 'when a type de champ does not have too many values' do
    let(:options) { (1..2).map(&:to_s) }

    it { is_expected.to have_content(type_de_champ.libelle) }

    it { is_expected.not_to have_link(text: "Voir toutes les valeurs possibles", href: prefill_type_de_champ_path(prefill_description.path, type_de_champ)) }
  end
end
