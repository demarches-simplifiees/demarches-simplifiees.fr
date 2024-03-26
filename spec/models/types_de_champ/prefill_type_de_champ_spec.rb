# frozen_string_literal: true

RSpec.describe TypesDeChamp::PrefillTypeDeChamp, type: :model do
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  let(:procedure) { create(:procedure) }

  describe '.build' do
    subject(:built) { described_class.build(type_de_champ, procedure.active_revision) }

    context 'when type de champ is drop_down_list' do
      let(:type_de_champ) { build(:type_de_champ_drop_down_list, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp) }
    end

    context 'when type de champ is multiple_drop_down_list' do
      let(:type_de_champ) { build(:type_de_champ_multiple_drop_down_list, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillMultipleDropDownListTypeDeChamp) }
    end

    context 'when type de champ is pays' do
      let(:type_de_champ) { build(:type_de_champ_pays, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillPaysTypeDeChamp) }
    end

    context 'when type de champ is regions' do
      let(:type_de_champ) { build(:type_de_champ_regions, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillRegionTypeDeChamp) }
    end

    context 'when type de champ is repetition' do
      let(:type_de_champ) { build(:type_de_champ_repetition, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillRepetitionTypeDeChamp) }
    end

    context 'when type de champ is departements' do
      let(:type_de_champ) { build(:type_de_champ_departements, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillDepartementTypeDeChamp) }
    end

    context 'when type de champ is communes' do
      let(:type_de_champ) { build(:type_de_champ_communes) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillCommuneTypeDeChamp) }
    end

    context 'when type de champ is address' do
      let(:type_de_champ) { build(:type_de_champ_address) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillAddressTypeDeChamp) }
    end

    context 'when type de champ is epci' do
      let(:type_de_champ) { build(:type_de_champ_epci, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillEpciTypeDeChamp) }
    end

    context 'when the type de champ is an annuaire_education' do
      let(:type_de_champ) { build(:type_de_champ_annuaire_education) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillAnnuaireEducationTypeDeChamp) }
    end

    context 'when any other type de champ' do
      let(:type_de_champ) { build(:type_de_champ_date, procedure: procedure) }

      it { expect(built).to be_kind_of(TypesDeChamp::PrefillTypeDeChamp) }
    end
  end

  describe '.wrap' do
    subject(:wrapped) { described_class.wrap([build(:type_de_champ_drop_down_list, procedure: procedure), build(:type_de_champ_email, procedure: procedure)], procedure.active_revision) }

    it 'wraps the collection' do
      expect(wrapped.first).to be_kind_of(TypesDeChamp::PrefillDropDownListTypeDeChamp)
      expect(wrapped.last).to be_kind_of(TypesDeChamp::PrefillTypeDeChamp)
    end
  end

  describe '#possible_values' do
    let(:built) { described_class.build(type_de_champ, procedure.active_revision) }
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
        let!(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list }]) }
        let(:type_de_champ) { procedure.draft_types_de_champ_public.first }
        let(:link_to_all_possible_values) {
          link_to(
            I18n.t("views.prefill_descriptions.edit.possible_values.link.text"),
            Rails.application.routes.url_helpers.prefill_type_de_champ_path(procedure.path, type_de_champ),
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
      let(:type_de_champ) { build(:type_de_champ_mesri, procedure: procedure) }

      it { expect(possible_values).to be_empty }
    end
  end

  describe '#example_value' do
    subject(:example_value) { described_class.build(type_de_champ, procedure.active_revision).example_value }

    context 'when the type de champ is not prefillable' do
      let(:type_de_champ) { build(:type_de_champ_mesri, procedure: procedure) }

      it { expect(example_value).to be_nil }
    end

    context 'when the type de champ is prefillable' do
      let(:type_de_champ) { build(:type_de_champ_email, procedure: procedure) }

      it { expect(example_value).to eq(I18n.t("views.prefill_descriptions.edit.examples.#{type_de_champ.type_champ}")) }
    end
  end

  describe '#to_assignable_attributes' do
    let(:type_de_champ) { build(:type_de_champ_email, procedure: procedure) }
    let(:champ) { build(:champ, type_de_champ: type_de_champ) }
    let(:value) { "any@email.org" }
    subject(:to_assignable_attributes) { described_class.build(type_de_champ, procedure.active_revision).to_assignable_attributes(champ, value) }

    it { is_expected.to match({ id: champ.id, value: value }) }
  end
end
