module Connections
  class CursorConnection < GraphQL::Pagination::Connection
    def initialize(items, deprecated_order: nil, **kwargs)
      super(items, **kwargs)
      @deprecated_order = deprecated_order
    end

    def nodes
      load_nodes
    end

    def has_previous_page
      load_nodes
      @has_previous_page
    end

    def has_next_page
      load_nodes
      @has_next_page
    end

    def cursor_for(item)
      cursor_from_column(item, order_column)
    end

    private

    def load_nodes
      @nodes ||= begin
        page_info = compute_page_info(before:, after:, first:, last:)
        nodes = resolve_nodes(**page_info.slice(:before, :after, :limit, :inverted))
        result_size = nodes.size
        @has_previous_page = page_info[:has_previous_page].(result_size)
        @has_next_page = page_info[:has_next_page].(result_size)

        trimmed_nodes = nodes.first(page_info[:expected_size])
        trimmed_nodes.reverse! if page_info[:inverted]
        trimmed_nodes
      end
    end

    def timestamp_and_id_from_cursor(cursor)
      timestamp, id = decode(cursor).split(';')
      [Time.zone.parse(timestamp), id.to_i]
    end

    def cursor_from_column(item, column)
      encode([item.read_attribute(column).utc.strftime("%Y-%m-%dT%H:%M:%S.%NZ"), item.id].join(';'))
    end

    def order_column
      :updated_at
    end

    def order_table
      raise StandardError, 'Not implemented'
    end

    def resolve_nodes(before:, after:, limit:, inverted:)
      order = inverted ? :desc : :asc
      nodes = items.order(order_column => order, id: order)
      nodes = nodes.limit(limit)

      if before.present?
        timestamp, id = timestamp_and_id_from_cursor(before)
        nodes.where("(#{order_table}.#{order_column}, #{order_table}.id) < (?, ?)", timestamp, id)
      elsif after.present?
        timestamp, id = timestamp_and_id_from_cursor(after)
        nodes.where("(#{order_table}.#{order_column}, #{order_table}.id) > (?, ?)", timestamp, id)
      else
        nodes
      end
    end

    # before and after are a serialized version of (timestamp, id)
    # first is a number (n) and mean take n element in order ascendant
    # last : n element in order descendant
    def compute_page_info(before: nil, after: nil, first: nil, last: nil)
      if first.present? && last.present?
        raise GraphQL::ExecutionError.new('Arguments "first" and "last" are exclusive', extensions: { code: :bad_request })
      end

      if before.present? && after.present?
        raise GraphQL::ExecutionError.new('Arguments "before" and "after" are exclusive', extensions: { code: :bad_request })
      end

      if first.present? && first < 0
        raise GraphQL::ExecutionError.new('Argument "first" must be a non-negative integer', extensions: { code: :bad_request })
      end

      if last.present? && last < 0
        raise GraphQL::ExecutionError.new('Argument "last" must be a non-negative integer', extensions: { code: :bad_request })
      end

      if @deprecated_order == :desc
        if last.present?
          first = [last, max_page_size].min
          last = nil
        else
          last = [first || default_page_size, max_page_size].min
          first = nil
        end
      end

      limit = [first || last || default_page_size, max_page_size].min + 1
      inverted = last.present? || before.present?

      {
        before:,
        after:,
        limit:,
        inverted:,
        expected_size: limit - 1,
        has_previous_page: -> (result_size) { after.present? || (result_size >= limit && inverted) },
        has_next_page: -> (result_size) { before.present? || (result_size >= limit && !inverted) }
      }
    end
  end
end
