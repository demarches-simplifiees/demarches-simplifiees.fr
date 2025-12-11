# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251210CleanCadreJuridiqueTask do
    describe '#process' do
      subject(:process) { described_class.process(procedure) }

      let(:procedure) { create(:procedure).tap { _1.update_column(:cadre_juridique, cadre_juridique) } }

      context 'with valid URL' do
        let(:cadre_juridique) { 'https://www.legifrance.gouv.fr' }

        it 'does not modify cadre_juridique' do
          expect { process }.not_to change { procedure.reload.cadre_juridique }
        end
      end

      context 'with legacy text reference' do
        let(:cadre_juridique) { 'Décret n° 2019-1088' }

        it 'does not modify cadre_juridique' do
          expect { process }.not_to change { procedure.reload.cadre_juridique }
        end
      end

      context 'with HTML tag' do
        let(:cadre_juridique) { '<a href="http://example.com">lien</a>' }

        it 'sets cadre_juridique to nil' do
          expect { process }.to change { procedure.reload.cadre_juridique }.to(nil)
        end
      end

      context 'with dangerous scheme' do
        let(:cadre_juridique) { 'javascript:void(0)' }

        it 'sets cadre_juridique to nil' do
          expect { process }.to change { procedure.reload.cadre_juridique }.to(nil)
        end
      end

      context 'with encoded HTML entities' do
        let(:cadre_juridique) { '&#60;script&#62;' }

        it 'sets cadre_juridique to nil' do
          expect { process }.to change { procedure.reload.cadre_juridique }.to(nil)
        end
      end
    end
  end
end
