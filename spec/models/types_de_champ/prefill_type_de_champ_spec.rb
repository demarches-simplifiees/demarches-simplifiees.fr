# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillTypeDeChamp, type: :model do
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  describe '.build' do
    subject(:built) { described_class.build(type_de_champ) }

    context 'when the type de champ is a drop_down_list' do
      let(:type_de_champ) { build(:type_de_champ_drop_down_list) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp) }
    end

    context 'when the type de champ is a pays' do
      let(:type_de_champ) { build(:type_de_champ_pays) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillPaysTypeDeChamp) }
    end

    context 'when the type de champ is a regions' do
      let(:type_de_champ) { build(:type_de_champ_regions) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillRegionTypeDeChamp) }
    end

    context 'when the type de champ is a repetition' do
      let(:type_de_champ) { build(:type_de_champ_repetition) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillRepetitionTypeDeChamp) }
    end

    context 'when the type de champ is a departements' do
      let(:type_de_champ) { build(:type_de_champ_departements) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillDepartementTypeDeChamp) }
    end

    context 'when the type de champ is a epci' do
      let(:type_de_champ) { build(:type_de_champ_epci) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillEpciTypeDeChamp) }
    end

    context 'when any other type de champ' do
      let(:type_de_champ) { build(:type_de_champ_date) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
    end
  end

  describe '.wrap' do
    subject(:wrapped) { described_class.wrap([build(:type_de_champ_drop_down_list), build(:type_de_champ_email)]) }

    it 'wraps the collection' do
      expect(wrapped.first).to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp)
      expect(wrapped.last).to be_kind_of(TypesDeChamp::PrefillTypeDeChamp)
    end
  end

  describe '#possible_values' do
    let(:built) { described_class.build(type_de_champ) }
    subject(:possible_values) { built.possible_values }

    context 'when the type de champ is prefillable' do
      context 'when the type de champ has a description' do
        let(:type_de_champ) { build(:type_de_champ_text) }

        it { expect(possible_values).to include(I18n.t("views.prefill_descriptions.edit.possible_values.#{type_de_champ.type_champ}_html")) }
      end

      context 'when the type de champ does not have a description' do
        let(:type_de_champ) { build(:type_de_champ_mesri) }

        it { expect(possible_values).not_to include(I18n.t("views.prefill_descriptions.edit.possible_values.#{type_de_champ.type_champ}_html")) }
      end

      describe 'too many possible values or not' do
        let!(:procedure) { create(:procedure, :with_drop_down_list) }
        let(:type_de_champ) { procedure.draft_types_de_champ_public.first }
        let(:link_to_all_possible_values) {
          link_to(
            I18n.t("views.prefill_descriptions.edit.possible_values.link.text"),
            Rails.application.routes.url_helpers.prefill_type_de_champ_path(type_de_champ.path, type_de_champ),
            title: new_tab_suffix(I18n.t("views.prefill_descriptions.edit.possible_values.link.title")),
            **external_link_attributes
          )
        }

        context 'when there is too many possible values' do
          before { type_de_champ.drop_down_options = (1..described_class::POSSIBLE_VALUES_THRESHOLD + 1).map(&:to_s) }

          it { expect(possible_values).to include(link_to_all_possible_values) }

          it { expect(possible_values).not_to include(built.all_possible_values.to_sentence) }
        end

        context 'when there is not too many possible values' do
          before { type_de_champ.drop_down_options = (1..described_class::POSSIBLE_VALUES_THRESHOLD - 1).map(&:to_s) }

          it { expect(possible_values).not_to include(link_to_all_possible_values) }

          it { expect(possible_values).to include(built.all_possible_values.to_sentence) }
        end
      end
    end

    context 'when the type de champ is not prefillable' do
      let(:type_de_champ) { build(:type_de_champ_mesri) }

      it { expect(possible_values).to be_empty }
    end
  end

  describe '#example_value' do
    subject(:example_value) { described_class.build(type_de_champ).example_value }

    context 'when the type de champ is not prefillable' do
      let(:type_de_champ) { build(:type_de_champ_mesri) }

      it { expect(example_value).to be_nil }
    end

    context 'when the type de champ is prefillable' do
      let(:type_de_champ) { build(:type_de_champ_email) }

      it { expect(example_value).to eq(I18n.t("views.prefill_descriptions.edit.examples.#{type_de_champ.type_champ}")) }
    end
  end

  describe '#to_assignable_attributes' do
    let(:type_de_champ) { build(:type_de_champ_email) }
    let(:champ) { build(:champ, type_de_champ: type_de_champ) }
    let(:value) { "any@email.org" }
    subject(:to_assignable_attributes) { described_class.build(type_de_champ).to_assignable_attributes(champ, value) }

    it { is_expected.to match({ id: champ.id, value: value }) }
  end
end
