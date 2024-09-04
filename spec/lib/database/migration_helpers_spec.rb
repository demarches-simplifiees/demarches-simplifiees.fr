# frozen_string_literal: true

describe Database::MigrationHelpers do
  describe 'handling duplicates' do
    class TestLabel < ApplicationRecord
    end

    before(:all) do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table "test_labels" do |t|
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
  end

  describe '.delete_orphans' do
    class TestPhysician < ApplicationRecord; end

    class TestPatient < ApplicationRecord; end

    class TestAppointment < ApplicationRecord; end

    before(:all) do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table "test_physicians" do |t|
          t.string :name
        end
        ActiveRecord::Migration.create_table "test_patients" do |t|
          t.string :name
        end
        ActiveRecord::Migration.create_table "test_appointments", id: false do |t|
          t.integer  :test_physician_id
          t.integer  :test_patient_id
          t.datetime :datetime
        end
      end
    end

    after(:all) do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.drop_table :test_physicians, force: true
        ActiveRecord::Migration.drop_table :test_patients, force: true
        ActiveRecord::Migration.drop_table :test_appointments, force: true
      end
    end

    let(:model) { ActiveRecord::Migration.new.extend(Database::MigrationHelpers) }

    subject do
      model.delete_orphans(:test_appointments, :test_patients)
    end

    context 'when there are orphan records' do
      before(:each) do
        phy1 = TestPhysician.create({ name: 'Ibn Sina' })
        phy2 = TestPhysician.create({ name: 'Louis Pasteur' })
        pa1 = TestPatient.create({ name: 'Chams ad-Dawla' })
        pa2 = TestPatient.create({ name: 'Joseph Meister' })
        ap1 = TestAppointment.create({ test_physician_id: phy1.id, test_patient_id: pa1.id, datetime: 2.months.ago })
        ap2 = TestAppointment.create({ test_physician_id: phy1.id, test_patient_id: pa1.id, datetime: 1.month.ago })
        ap3 = TestAppointment.create({ test_physician_id: phy2.id, test_patient_id: pa2.id, datetime: 2.days.ago })
        ap4 = TestAppointment.create({ test_physician_id: phy1.id, test_patient_id: pa2.id, datetime: 1.day.ago })
        ap5 = TestAppointment.create({ test_physician_id: phy1.id, test_patient_id: pa1.id, datetime: Time.zone.today })

        # Appointments missing the associated patient
        ap6 = TestAppointment.create({ test_physician_id: phy1.id, test_patient_id: 9999, datetime: 3.months.ago })
        ap7 = TestAppointment.create({ test_physician_id: phy1.id, test_patient_id: 8888, datetime: 2.months.ago })
        ap8 = TestAppointment.create({ test_physician_id: phy2.id, test_patient_id: 8888, datetime: 1.month.ago })

        # Appointments missing the associated physician
        ap9 = TestAppointment.create({ test_physician_id: 7777, test_patient_id: pa1.id, datetime: 3.months.ago })
      end

      it 'deletes orphaned records on the specified key' do
        expect { subject }.to change { TestAppointment.count }.by(-3)

        # rubocop:disable Rails/WhereEquals
        appointments_with_missing_patients = TestAppointment
          .joins('LEFT OUTER JOIN test_patients ON test_patients.id = test_appointments.test_patient_id')
          .where('test_patients.id IS NULL')
        # rubocop:enable Rails/WhereEquals
        expect(appointments_with_missing_patients.count).to eq(0)
      end

      it 'keeps orphaned records on another key' do
        subject

        # rubocop:disable Rails/WhereEquals
        appointments_with_missing_physicians = TestAppointment
          .joins('LEFT OUTER JOIN test_physicians ON test_physicians.id = test_appointments.test_physician_id')
          .where('test_physicians.id IS NULL')
        # rubocop:enable Rails/WhereEquals
        expect(appointments_with_missing_physicians.count).not_to eq(0)
      end

      it 'keeps valid associated records' do
        expect { subject }.not_to change { [TestPhysician.count, TestPatient.count] }
      end
    end

    context 'when there are no orphaned records' do
      before(:each) do
        phy1 = TestPhysician.create({ name: 'Ibn Sina' })
        pa1 = TestPatient.create({ name: 'Chams ad-Dawla' })
        ap1 = TestAppointment.create({ test_physician_id: phy1.id, test_patient_id: pa1.id, datetime: 2.months.ago })
      end

      it 'doesn’t remove any records' do
        expect { subject }.not_to change { [TestPhysician.count, TestPatient.count, TestAppointment.count] }
      end
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
