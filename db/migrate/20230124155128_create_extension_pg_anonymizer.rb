class CreateExtensionPgAnonymizer < ActiveRecord::Migration[6.1]
  if ENV["PG_ANONYMIZER_ROLE"].present?
    def up
      safety_assured do
        execute <<~SQL.squish
          CREATE EXTENSION IF NOT EXISTS anon CASCADE;
        SQL

        execute <<~SQL.squish
          SELECT anon.init();
          SELECT anon.start_dynamic_masking();
        SQL

        execute <<~SQL.squish
          SECURITY LABEL FOR anon ON ROLE #{ENV["PG_ANONYMIZER_ROLE"]} IS 'MASKED';
        SQL
      end
    end

    def down
      safety_assured do
        execute <<~SQL.squish
          DROP EXTENSION anon CASCADE;
        SQL
      end
    end
  end
end
