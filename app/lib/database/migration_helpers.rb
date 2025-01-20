# frozen_string_literal: true

# Some of this file is lifted from Gitlab's `lib/gitlab/database/migration_helpers.rb`

# Copyright (c) 2011-present GitLab B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Database::MigrationHelpers
  # Given a combination of columns, return the records that appear twice of more
  # with the same values.
  #
  # Returns tuples of ids.
  #
  # Example:
  #
  #   find_duplicates :tags, [:post_id, :label]
  #   # [[7, 3], [1, 9, 4]]
  def find_duplicates(table_name, column_names)
    str_column_names = column_names.map(&:to_s)
    columns = str_column_names.join(', ')
    t_columns = str_column_names.map { |c| "t.#{c}" }.join(', ')

    duplicates = execute <<-SQL.squish
      SELECT t.id, #{t_columns}
      FROM #{table_name} t
      INNER JOIN (
        SELECT #{columns}, COUNT(*)
          FROM #{table_name}
          GROUP BY #{columns}
          HAVING COUNT(*) > 1
      ) dt
      ON #{column_names.map { |c| "t.#{c} = dt.#{c}" }.join(' AND ')}
    SQL

    grouped_duplicates = duplicates
      .group_by { |r| r.values_at(*str_column_names) }
      .values

    # Return the duplicate ids only (instead of a heavier record)
    grouped_duplicates.map do |records|
      records.map { |r| r["id"] }
    end
  end

  # Given a combination of columns, delete the records that appear twice of more
  # with the same values.
  #
  # The first record found is kept, and the other are discarded.
  #
  # Example:
  #
  #   delete_duplicates :tags, [:post_id, :label]
  def delete_duplicates(table_name, column_names)
    duplicates = nil
    disable_statement_timeout do
      duplicates = find_duplicates(table_name, column_names)
    end

    duplicates.each do |ids|
      duplicate_ids = ids.drop(1) # drop all records except the first
      execute "DELETE FROM #{table_name} WHERE (#{table_name}.id IN (#{duplicate_ids.join(', ')}))"
    end
  end

  # Creates a new index, concurrently
  #
  # Example:
  #
  #     add_concurrent_index :users, :some_column
  #
  # See Rails' `add_index` for more info on the available arguments.
  def add_concurrent_index(table_name, column_name, **options)
    if transaction_open?
      raise 'add_concurrent_index can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
    end

    options = options.merge({ algorithm: :concurrently })

    if index_exists?(table_name, column_name, **options)
      Rails.logger.warn "Index not created because it already exists (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"
      return
    end

    disable_statement_timeout do
      add_index(table_name, column_name, **options)
    end
  end

  # Delete records from `from_table` having a reference to a missing record in `to_table`.
  # This is useful to rectify data before adding a proper foreign_key.
  #
  # Example:
  #
  #     delete_orphans :appointments, :physicians
  #
  def delete_orphans(from_table, to_table)
    say_with_time "Deleting records from #{from_table} where the associated #{to_table.to_s.singularize} no longer exists" do
      from_table = Arel::Table.new(from_table)
      to_table = Arel::Table.new(to_table)
      foreign_key_column = foreign_key_column_for(to_table.name, "id")

      # Select the ids of orphan records
      arel_select = from_table
        .join(to_table, Arel::Nodes::OuterJoin).on(to_table[:id].eq(from_table[foreign_key_column]))
        .where(to_table[:id].eq(nil))
        .project(from_table[foreign_key_column])
      missing_record_ids = query_values(arel_select.to_sql)

      # Delete the records having ids referencing missing data
      arel_delete = Arel::DeleteManager.new()
        .from(from_table)
        .where(from_table[foreign_key_column].in(missing_record_ids.uniq))
      exec_delete(arel_delete.to_sql)
    end
  end

  private

  def statement_timeout_disabled?
    # This is a string of the form "100ms" or "0" when disabled
    connection.select_value('SHOW statement_timeout') == "0"
  end

  # Long-running migrations may take more than the timeout allowed by
  # the database. Disable the session's statement timeout to ensure
  # migrations don't get killed prematurely.
  #
  # There are two possible ways to disable the statement timeout:
  #
  # - Per transaction (this is the preferred and default mode)
  # - Per connection (requires a cleanup after the execution)
  #
  # When using a per connection disable statement, code must be inside
  # a block so we can automatically execute `RESET ALL` after block finishes
  # otherwise the statement will still be disabled until connection is dropped
  # or `RESET ALL` is executed
  def disable_statement_timeout
    if block_given?
      if statement_timeout_disabled?
        # Don't do anything if the statement_timeout is already disabled
        # Allows for nested calls of disable_statement_timeout without
        # resetting the timeout too early (before the outer call ends)
        yield
      else
        begin
          execute('SET statement_timeout TO 0')

          yield
        ensure
          execute('RESET ALL')
        end
      end
    else
      unless transaction_open?
        raise <<~ERROR
          Cannot call disable_statement_timeout() without a transaction open or outside of a transaction block.
          If you don't want to use a transaction wrap your code in a block call:

          disable_statement_timeout { # code that requires disabled statement here }

          This will make sure statement_timeout is disabled before and reset after the block execution is finished.
        ERROR
      end

      execute('SET LOCAL statement_timeout TO 0')
    end
  end

  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
end
