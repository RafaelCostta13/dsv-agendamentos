require "test_helper"

class DatabaseStructureTest < ActiveSupport::TestCase
  test "only the six planned tables and Rails migration metadata exist" do
    tables = connection.tables - %w[schema_migrations ar_internal_metadata]
    assert_equal %w[audit_events bookings login_attempts sessions slot_blocks users], tables.sort
  end

  test "columns use native PostgreSQL types sizes nullability and defaults" do
    expected = {
      bookings: {
        id: [ :integer, 8, false ], protocol: [ :string, 50, false ], request_id: [ :uuid, nil, false ],
        booking_date: [ :date, nil, false ], dock_number: [ :integer, 2, false ], slot_number: [ :integer, 2, false ],
        operation: [ :string, 20, false ], status: [ :string, 30, false ], contact_name: [ :string, 80, false ],
        company: [ :string, 100, false ], invoice: [ :string, 44, false ], plate: [ :string, 7, false ],
        vehicle_model: [ :string, 80, false ], checkin_at: [ :datetime, nil, true ],
        released_at: [ :datetime, nil, true ], release_remark: [ :text, nil, true ], change_reason: [ :text, nil, true ],
        lock_version: [ :integer, 4, false ], created_at: [ :datetime, nil, false ], updated_at: [ :datetime, nil, false ]
      },
      slot_blocks: {
        id: [ :integer, 8, false ], blocked_date: [ :date, nil, false ], dock_number: [ :integer, 2, false ],
        slot_number: [ :integer, 2, false ], reason: [ :string, 250, true ],
        created_at: [ :datetime, nil, false ], updated_at: [ :datetime, nil, false ]
      },
      audit_events: {
        id: [ :integer, 8, false ], entity_type: [ :string, 50, false ], entity_id: [ :integer, 8, false ],
        action: [ :string, 50, false ], previous_values: [ :jsonb, nil, true ], new_values: [ :jsonb, nil, true ],
        reason: [ :text, nil, true ], created_at: [ :datetime, nil, false ], actor_user_id: [ :integer, 8, true ],
        actor_name: [ :string, 100, true ], actor_role: [ :string, 30, true ], origin: [ :string, 30, true ]
      },
      users: {
        id: [ :integer, 8, false ], name: [ :string, 100, false ], email: [ :string, 254, false ],
        password_digest: [ :string, nil, false ], role: [ :string, 30, false ], active: [ :boolean, nil, false ],
        must_change_password: [ :boolean, nil, false ], password_changed_at: [ :datetime, nil, true ],
        deactivated_at: [ :datetime, nil, true ], lock_version: [ :integer, 4, false ],
        created_at: [ :datetime, nil, false ], updated_at: [ :datetime, nil, false ]
      },
      sessions: {
        id: [ :integer, 8, false ], user_id: [ :integer, 8, false ], token_digest: [ :string, 64, false ],
        last_seen_at: [ :datetime, nil, false ], expires_at: [ :datetime, nil, false ], revoked_at: [ :datetime, nil, true ],
        user_agent: [ :string, 500, true ], created_at: [ :datetime, nil, false ], updated_at: [ :datetime, nil, false ]
      },
      login_attempts: {
        id: [ :integer, 8, false ], key_kind: [ :string, 10, false ], key_digest: [ :string, 64, false ],
        occurred_at: [ :datetime, nil, false ]
      }
    }
    expected.each do |table, columns|
      actual = connection.columns(table).index_by { |column| column.name.to_sym }
      assert_equal columns.keys.sort, actual.keys.sort, table.to_s
      assert_equal "id", connection.primary_key(table)
      columns.each do |name, properties|
        column = actual.fetch(name)
        assert_equal properties, [ column.type, column.limit, column.null ], "#{table}.#{name}"
        assert_equal 6, column.precision if column.type == :datetime
        next if name == :id

        if name == :status
          assert_equal "agendado", column.default
        elsif name == :lock_version
          assert_equal "0", column.default.to_s
        elsif table == :users && %i[active must_change_password].include?(name)
          assert_equal "true", column.default.to_s
        else
          assert_nil column.default, "Unexpected default for #{table}.#{name}"
          assert_nil column.default_function
        end
      end
    end
  end

  test "all planned indexes exist with the correct unique columns and partial predicates" do
    indexes = connection.indexes(:bookings).index_by(&:name)
    assert_equal 5, indexes.size
    assert_index indexes.fetch("index_bookings_on_protocol"), [ "protocol" ], true
    assert_index indexes.fetch("index_bookings_on_request_id"), [ "request_id" ], true
    assert_index indexes.fetch("index_bookings_on_booking_date"), [ "booking_date" ], false
    capacity = indexes.fetch("bookings_active_slot_unique")
    assert_index capacity, %w[booking_date dock_number slot_number], true
    assert_equal %w[agendado em_operacao liberado], capacity.where.scan(/'(.*?)'/).flatten
    occupation = indexes.fetch("bookings_dock_occupation_unique")
    assert_index occupation, [ "dock_number" ], true
    assert_equal [ "em_operacao" ], occupation.where.scan(/'(.*?)'/).flatten
    %w[index_bookings_on_protocol index_bookings_on_request_id index_bookings_on_booking_date].each do |name|
      assert_nil indexes.fetch(name).where
    end

    blocks = connection.indexes(:slot_blocks)
    assert_equal 1, blocks.size
    assert_index blocks.first, %w[blocked_date dock_number slot_number], true
    assert_nil blocks.first.where
    audit = connection.indexes(:audit_events).index_by(&:name)
    assert_equal 3, audit.size
    assert_index audit.fetch("index_audit_events_on_entity_type_and_entity_id"), %w[entity_type entity_id], false
    assert_index audit.fetch("index_audit_events_on_actor_user_id"), [ "actor_user_id" ], false
    assert_index audit.fetch("index_audit_events_on_origin"), [ "origin" ], false
    sessions = connection.indexes(:sessions).index_by(&:name)
    assert_equal 4, sessions.size
    assert_index sessions.fetch("index_sessions_on_token_digest"), [ "token_digest" ], true
    assert_index sessions.fetch("index_sessions_on_user_id"), [ "user_id" ], false
    assert_index sessions.fetch("index_sessions_on_expires_at"), [ "expires_at" ], false
    assert_index sessions.fetch("index_sessions_on_revoked_at"), [ "revoked_at" ], false
    attempts = connection.indexes(:login_attempts).index_by(&:name)
    assert_equal 2, attempts.size
    assert_index attempts.fetch("login_attempts_lookup"), %w[key_kind key_digest occurred_at], false
    assert_index attempts.fetch("index_login_attempts_on_occurred_at"), [ "occurred_at" ], false
  end

  test "named check constraints are installed and validated" do
    {
      bookings: %w[bookings_dock_range bookings_slot_range bookings_operation_allowed bookings_status_allowed
        bookings_invoice_digits bookings_lock_version_nonnegative bookings_release_chronology
        bookings_operation_checkin bookings_released_details],
      slot_blocks: %w[slot_blocks_dock_range slot_blocks_slot_range],
      audit_events: %w[audit_events_entity_type_allowed audit_events_actor_role_allowed audit_events_origin_allowed audit_events_actor_snapshot_complete],
      sessions: %w[sessions_token_digest_length sessions_valid_times],
      login_attempts: %w[login_attempts_kind_allowed login_attempts_digest_length]
    }.each do |table, names|
      constraints = connection.check_constraints(table)
      assert_equal names.sort, constraints.map(&:name).sort
      assert constraints.all?(&:validated?)
      if table == :audit_events
        assert_equal [ "users" ], connection.foreign_keys(table).map(&:to_table)
      elsif table == :sessions
        assert_equal [ "users" ], connection.foreign_keys(table).map(&:to_table)
      else
        assert_empty connection.foreign_keys(table)
      end
    end
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def assert_index(index, columns, unique)
    assert_equal columns, index.columns
    assert_equal unique, index.unique
  end
end
