class AddLinkToServices < ActiveRecord::Migration[7.0]
  def up
    add_column :services, :link, :string
    safety_assured do
      execute <<-SQL
        ALTER TABLE services DROP CONSTRAINT IF EXISTS services_email_or_contact_page_null;
        ALTER TABLE services ADD CONSTRAINT services_email_or_contact_page_null 
          CHECK (
            (email IS NOT NULL AND email != '') OR 
            (link IS NOT NULL AND link <> '')
          );
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        ALTER TABLE services DROP CONSTRAINT IF EXISTS services_email_or_contact_page_null;
        ALTER TABLE services ADD CONSTRAINT services_email_or_contact_page_null 
          CHECK (email IS NOT NULL AND email <> '');
      SQL
    end
    remove_column :services, :link
  end
end
