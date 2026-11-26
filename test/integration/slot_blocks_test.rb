require "test_helper"
require_relative "../support/booking_data"

class SlotBlocksTest < ActionDispatch::IntegrationTest
  include BookingData
  setup { @authenticated_user = sign_in_as }

  def input(overrides = {})
    { blocked_date: (Date.current+1).iso8601, dock_numbers: [ "1" ], slot_numbers: [ "1" ], reason: "Manutenção interna" }.merge(overrides)
  end

  test "management page uses native selection controls sidebar and restrictive CSP" do
    get admin_slot_blocks_path
    assert_response :success
    assert_select "h1", "Bloqueios de docas e horários"
    assert_select "nav a[aria-current='page']", text: /Bloqueios/
    assert_select "button[name='selected_date']", count: 3
    assert_select "input[name='slot_block[dock_numbers][]'][type='checkbox']", count: 8
    assert_select "input[name='slot_block[slot_numbers][]'][type='checkbox']", count: 10
    assert_select "script", count: 0
    assert_includes response.headers.fetch("Content-Security-Policy"), "script-src 'none'"
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "server select all clear and date switches preserve reason and never write" do
    travel_to Time.zone.local(2026, 11, 25, 14, 30) do
      values = input(blocked_date: Date.current.iso8601)
      assert_no_difference [ "SlotBlock.count", "AuditEvent.count" ] do
        post admin_slot_blocks_path, params: { slot_block: values, selection_command: "all_docks" }
        assert_select "input[name='slot_block[dock_numbers][]'][checked]", count: 8
        post admin_slot_blocks_path, params: { slot_block: values, selection_command: "clear_docks" }
        assert_select "input[name='slot_block[dock_numbers][]'][checked]", count: 0
        post admin_slot_blocks_path, params: { slot_block: values, selection_command: "all_slots" }
        assert_select "input[name='slot_block[slot_numbers][]'][checked]", count: 3
        assert_select "input[name='slot_block[slot_numbers][]'][disabled]", count: 7
        [ 1, 2 ].each do |offset|
          post admin_slot_blocks_path, params: { slot_block: values, selected_date: (Date.current+offset).iso8601 }
          assert_select "textarea", text: values[:reason]
          assert_select "input[name='slot_block[slot_numbers][]'][disabled]", count: 0
        end
      end
    end
  end

  test "review is read only calculates the true batch size and commit creates one row and audit per position" do
    values = input(dock_numbers: [ "1", "2" ], slot_numbers: [ "1", "2", "3" ])
    assert_no_difference [ "SlotBlock.count", "AuditEvent.count" ] do
      post admin_slot_blocks_path, params: { slot_block: values, intent: "review", total_positions: 9999 }
      assert_response :success
      assert_select "h1", "Confirmar bloqueio"
      assert_includes response.body, "bloquear 6 posições"
    end
    post admin_slot_blocks_path, params: { slot_block: values, selection_command: "back" }
    assert_response :success
    assert_select "textarea", text: values[:reason]
    assert_select "input[name='slot_block[dock_numbers][]'][checked]", count: 2
    assert_difference [ "SlotBlock.count", "AuditEvent.count" ], 6 do
      post admin_slot_blocks_path, params: { slot_block: values, intent: "confirm" }
    end
    assert_response :see_other
    follow_redirect!
    assert_select "[role='status']", text: /6 posições bloqueadas/
    assert_select "#existing-blocks tbody tr", count: 6
  end

  test "conflicts reject whole batch display position and preserve selections" do
    booking = Booking.create!(booking_attributes(booking_date: Date.current+1, dock_number: 2, slot_number: 3))
    assert_no_difference [ "SlotBlock.count", "AuditEvent.count" ] do
      post admin_slot_blocks_path, params: { slot_block: input(dock_numbers: [ 1, 2 ], slot_numbers: [ 1, 2, 3 ]) }
    end
    assert_response :conflict
    assert_select ".admin-conflicts li", text: /Doca 02.*10:00.*11:00/
    assert_select "textarea", text: "Manutenção interna"
    assert_select "input[name='slot_block[dock_numbers][]'][checked]", count: 2
    assert_equal "agendado", booking.reload.status
  end

  test "blocked slots are unavailable publicly without exposing reason and dashboard links reveal it only in admin" do
    post admin_slot_blocks_path, params: { slot_block: input }
    record = SlotBlock.last
    post bookings_path, params: { booking: booking_attributes(booking_date: Date.current+1).except(:protocol), intent: "availability" }
    assert_select "input[name='booking[slot_number]'][value='1'][disabled]"
    refute_includes response.body, "Manutenção interna"
    assert_no_difference "Booking.count" do
      post bookings_path, params: { booking: booking_attributes(booking_date: Date.current+1).except(:protocol) }
    end
    assert_response :conflict
    refute_includes response.body, "Manutenção interna"
    get admin_root_path(date: (Date.current+1).iso8601)
    assert_select "td[data-state='blocked'] a[title='Manutenção interna']"
    assert_select "[data-indicator='available'] strong", "79"
    assert_select "[data-indicator='bookings'] strong", "0"
    assert_select "a[href='#{admin_slot_blocks_path(date: (Date.current+1).iso8601, dock_number: 1, anchor: "block-#{record.id}")}']"
    get admin_slot_blocks_path(date: (Date.current+1).iso8601, dock_number: 1)
    assert_select "td", text: "Manutenção interna"
  end

  test "individual unblock requires confirmation snapshot and leaves block audit after deletion" do
    post admin_slot_blocks_path, params: { slot_block: input }
    record = SlotBlock.last
    assert_no_difference "SlotBlock.count" do
      get unblocking_admin_slot_block_path(record)
    end
    assert_response :success
    assert_select "h1", "Confirmar desbloqueio"
    assert_select "td", text: "Manutenção interna"
    token = css_select("input[name='block_tokens[]']").first["value"]
    assert_difference "SlotBlock.count", -1 do
      delete admin_slot_block_path(record), params: { block_tokens: [ token ] }
    end
    assert_response :see_other
    assert_equal 1, AuditEvent.where(entity_id: record.id, action: "block").count
    assert_equal 1, AuditEvent.where(entity_id: record.id, action: "unblock").count
    get admin_root_path(date: (Date.current+1).iso8601)
    assert_select "td[data-state='blocked']", count: 0
    assert_select "[data-indicator='available'] strong", "80"
  end

  test "list filters pagination and select all refer only to the eligible rows of the displayed page" do
    form = BlockSelection.new(input(dock_numbers: (1..8).to_a, slot_numbers: (1..10).to_a))
    assert BlockSlots.new(form).call
    get admin_slot_blocks_path(date: (Date.current+1).iso8601)
    assert_select "#existing-blocks tbody tr", count: 25
    post review_unblock_admin_slot_blocks_path(date: (Date.current+1).iso8601, page: 2), params: { intent: "select_page" }
    assert_select "input[name='block_tokens[]'][checked]", count: 25
    tokens = css_select("input[name='block_tokens[]'][checked]").map { |node| node["value"] }
    ids = tokens.map { |token| SlotBlock.decode_unlock_token(token)["id"] }
    expected = SlotBlock.order(:blocked_date, :dock_number, :slot_number, :id).limit(25).offset(25).pluck(:id)
    assert_equal expected, ids
    post review_unblock_admin_slot_blocks_path, params: { block_tokens: tokens }
    assert_response :success
    assert_includes response.body, "25 bloqueios"
    post bulk_unblock_admin_slot_blocks_path, params: { block_tokens: tokens }
    assert_response :see_other
    assert_equal 55, SlotBlock.count
    get admin_slot_blocks_path(date: (Date.current+1).iso8601, dock_number: 8)
    assert_select "#existing-blocks tbody tr", count: 10
    assert_select "td", text: "08", count: 11
  end

  test "historic queries are read only and invalid filters or parameters never trigger internal errors" do
    historic = SlotBlock.create!(blocked_date: Date.current-1, dock_number: 1, slot_number: 1)
    get admin_slot_blocks_path(date: historic.blocked_date.iso8601)
    assert_response :success
    assert_select "input[name='block_tokens[]'][disabled]", count: 1
    assert_select "#existing-blocks a", text: "Desbloquear", count: 0
    get unblocking_admin_slot_block_path(historic)
    assert_response :unprocessable_entity
    [ { date: "bad" }, { dock_number: "1 OR 1=1" } ].each do |query|
      get admin_slot_blocks_path(query)
      assert_response :success
      assert_select "[role='alert']"
      assert_select "#existing-blocks tbody tr", count: 0
    end
    assert_no_difference "SlotBlock.count" do
      post admin_slot_blocks_path, params: { slot_block: input(dock_numbers: [ "1 OR 1=1" ]) }
      assert_response :unprocessable_entity
      post bulk_unblock_admin_slot_blocks_path, params: { block_tokens: [ "1 OR 1=1" ] }
      assert_response :conflict
    end
    get unblocking_admin_slot_block_path(id: 99999999999)
    assert_response :not_found
    assert_select "h1", "Bloqueio não encontrado"
  end

  test "stored reason is escaped and forged state or timestamps are ignored" do
    attack = "<script>alert(1)</script>"
    post admin_slot_blocks_path, params: { slot_block: input(reason: attack).merge(id: 99999, status: "agendado", created_at: "2000-01-01") }
    assert_response :see_other
    record = SlotBlock.last
    assert_not_equal 99999, record.id
    refute_equal 2000, record.created_at.year
    follow_redirect!
    assert_select "script", count: 0
    assert_includes response.body, "&lt;script&gt;"
    refute_includes response.body, attack
    get admin_root_path(date: (Date.current+1).iso8601)
    assert_select "script", count: 1
    assert_select "script[src*=dashboard_polling][nonce]", count: 1
    assert_select "script:not([src])", count: 0
    refute_includes response.body, attack
  end

  test "CSRF is enforced on create and both unlock paths while valid tokens work" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post admin_slot_blocks_path, params: { slot_block: input }
    assert_response :unprocessable_entity
    get admin_slot_blocks_path
    token = css_select("meta[name='csrf-token']").first["content"]
    post admin_slot_blocks_path, params: { slot_block: input, authenticity_token: token }
    assert_response :see_other
    record = SlotBlock.last
    [ [ :delete, admin_slot_block_path(record) ], [ :post, bulk_unblock_admin_slot_blocks_path ] ].each do |verb, path|
      assert_no_difference "SlotBlock.count" do
        public_send(verb, path, params: { block_tokens: [ record.unlock_token ] })
        assert_response :unprocessable_entity
      end
    end
    get unblocking_admin_slot_block_path(record)
    token = css_select("meta[name='csrf-token']").first["content"]
    delete admin_slot_block_path(record), params: { block_tokens: [ record.unlock_token ], authenticity_token: token }
    assert_response :see_other
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  test "original public replay after cancellation remains idempotent when its old slot is blocked" do
    original = BookingRequest.new(booking_attributes(booking_date: Date.current+1).except(:protocol))
    booking = CreateBooking.call(original)
    change = BookingChangeRequest.new(change_reason: "Cancelado antes do bloqueio", lock_version: 0)
    assert ChangeBooking.new(booking_id: booking.id, action: "cancel", form: change).call
    assert BlockSlots.new(BlockSelection.new(input)).call
    before = booking.reload.attributes
    assert_no_difference [ "Booking.count", "AuditEvent.count", "SlotBlock.count" ] do
      post bookings_path, params: { booking: original.booking_attributes }
      assert_response :see_other
    end
    assert_equal before, booking.reload.attributes
    assert_equal "cancelado", booking.status
  end

  test "all slot block routes are absent in production" do
    Rails.stub(:env, "production".inquiry) do
      Rails.application.reload_routes!
      { get: %w[/admin/slot_blocks /admin/slot_blocks/1/unblocking], post: %w[/admin/slot_blocks /admin/slot_blocks/review_unblock /admin/slot_blocks/bulk_unblock], delete: %w[/admin/slot_blocks/1] }.each do |verb, paths|
        paths.each { |path| assert_raises(ActionController::RoutingError) { Rails.application.routes.recognize_path(path, method: verb) } }
      end
    end
  ensure
    Rails.application.reload_routes!
  end
end
