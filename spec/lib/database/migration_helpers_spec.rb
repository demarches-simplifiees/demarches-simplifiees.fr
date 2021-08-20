describe Database::MigrationHelpers do
  class TestLabel < ApplicationRecord
  end

  before(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table "test_labels", force: true do |t|
        t.string :label
        t.integer :user_id
      end
    end
  end

  before(:each) do
    # User 1 labels
    TestLabel.create({ id: 1, label: 'Important', user_id: 1 })
    TestLabel.create({ id: 2, label: 'Urgent', user_id: 1 })
    TestLabel.create({ id: 3, label: 'Done', user_id: 1 })
    TestLabel.create({ id: 4, label: 'Bug', user_id: 1 })

    # User 2 labels
    TestLabel.create({ id: 5, label: 'Important', user_id: 2 })
    TestLabel.create({ id: 6, label: 'Critical', user_id: 2 })

    # Duplicates
    TestLabel.create({ id: 7, label: 'Urgent', user_id: 1 })
    TestLabel.create({ id: 8, label: 'Important', user_id: 2 })
  end

  after(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.drop_table :test_labels, force: true
    end
  end

  let(:model) { ActiveRecord::Migration.new.extend(Database::MigrationHelpers) }

  describe '.find_duplicates' do
    context 'using a single column for uniqueness' do
      subject do
        model.find_duplicates(:test_labels, [:label])
      end

      it 'finds duplicates' do
        expect(subject.length).to eq 2
      end

      it 'finds three labels with "Important"' do
        expect(subject).to include [1, 5, 8]
      end

      it 'finds two labels with "Urgent"' do
        expect(subject).to include [2, 7]
      end
    end

    context 'using multiple columns for uniqueness' do
      subject do
        model.find_duplicates(:test_labels, [:label, :user_id])
      end

      it 'finds duplicates' do
        expect(subject.length).to eq 2
      end

      it 'finds two labels with "Important" for user 2' do
        expect(subject).to include [5, 8]
      end

      it 'finds two labels with "Urgent" for user 1' do
        expect(subject).to include [2, 7]
      end
    end
  end

  describe '.delete_duplicates' do
    subject do
      model.delete_duplicates(:test_labels, [:label])
    end

    it 'keeps the first item, and delete the others' do
      expect { subject }.to change(TestLabel, :count).by(-3)
      expect(TestLabel.where(label: 'Critical').count).to eq(1)
      expect(TestLabel.where(label: 'Important').count).to eq(1)
      expect(TestLabel.where(label: 'Urgent').count).to eq(1)
      expect(TestLabel.where(label: 'Bug').count).to eq(1)
      expect(TestLabel.where(label: 'Done').count).to eq(1)
    end
  end

  describe '.add_concurrent_index' do
    let(:model) { ActiveRecord::Migration.new.extend(Database::MigrationHelpers) }

    context 'outside a transaction' do
      before do
        model.verbose = false
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:disable_statement_timeout).and_call_original
      end

      it 'creates the index concurrently' do
        expect(model).to receive(:add_index)
          .with(:users, :foo, algorithm: :concurrently)

        model.add_concurrent_index(:users, :foo)
      end

      it 'creates unique index concurrently' do
        expect(model).to receive(:add_index)
          .with(:users, :foo, { algorithm: :concurrently, unique: true })

        model.add_concurrent_index(:users, :foo, unique: true)
      end

      it 'does nothing if the index exists already' do
        expect(model).to receive(:index_exists?)
          .with(:users, :foo, { algorithm: :concurrently, unique: true }).and_return(true)
        expect(model).not_to receive(:add_index)

        model.add_concurrent_index(:users, :foo, unique: true)
      end
    end

    context 'inside a transaction' do
      it 'raises RuntimeError' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect { model.add_concurrent_index(:users, :foo) }
          .to raise_error(RuntimeError)
      end
    end
  end
end
