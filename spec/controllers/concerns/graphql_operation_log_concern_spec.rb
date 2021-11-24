RSpec.describe GraphqlOperationLogConcern, type: :controller do
  class TestController < ActionController::Base
    include GraphqlOperationLogConcern
  end

  controller TestController do
  end

  describe '#operation_log' do
    let(:query) { nil }
    let(:variables) { nil }
    let(:operation_name) { nil }

    subject { controller.operation_log(query, operation_name, variables) }

    context 'with no query' do
      it { expect(subject).to eq('NoQuery') }
    end

    context 'with invalid query' do
      let(:query) { 'query { demarche {} }' }

      it { expect(subject).to eq('InvalidQuery') }
    end

    context 'with two queries' do
      let(:query) { 'query demarche { demarche } query dossier { dossier }' }
      let(:operation_name) { 'dossier' }

      it { expect(subject).to eq('query: dossier { dossier }') }
    end

    context 'with arguments' do
      let(:query) { 'query demarche { demarche(number: 123) { id } }' }

      it { expect(subject).to eq('query: demarche { demarche } number: "123"') }
    end

    context 'with variables' do
      let(:query) { 'query { demarche(number: 123) { id } }' }
      let(:variables) { { number: 124 } }

      it { expect(subject).to eq('query: { demarche } number: "124"') }
    end

    context 'with mutation and arguments' do
      let(:query) { 'mutation { passerDossierEnInstruction(input: { number: 123 }) { id } }' }

      it { expect(subject).to eq('mutation: { passerDossierEnInstruction } number: "123"') }
    end

    context 'with mutation and variables' do
      let(:query) { 'mutation { passerDossierEnInstruction(input: { number: 123 }) { id } }' }
      let(:variables) { { input: { number: 124 } } }

      it { expect(subject).to eq('mutation: { passerDossierEnInstruction } number: "124"') }
    end
  end
end
