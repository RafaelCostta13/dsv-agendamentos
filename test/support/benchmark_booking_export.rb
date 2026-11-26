# Explicit opt-in benchmark; never runs against operational data.
require_relative "../../config/environment"
abort "Benchmark is restricted to test" unless Rails.env.test?
require "securerandom"
require "json"
$stdout.sync = true
count = Integer(ENV.fetch("RF012_ROWS"))
abort "Unsupported benchmark size" unless [ 100, 1000, 5000, 10000, 20000 ].include?(count)
tag = "RF012-BENCH-#{SecureRandom.hex(6)}"
output = {}
ApplicationRecord.transaction do
  count.times.each_slice(1000) do |slice|
    attributes = slice.map do |index|
      date = Date.new(2025, 1, 1)+index/80
      { protocol: "#{tag}-#{index}", request_id: SecureRandom.uuid, booking_date: date, dock_number: (index/10)%8+1, slot_number: index%10+1,
        operation: index.even? ? "entrega" : "coleta", status: "liberado", contact_name: "Operador de teste", company: tag,
        invoice: "0"+"1"*43, plate: "TES1A23", vehicle_model: "Caminhão de teste", checkin_at: date.in_time_zone+8.hours,
        released_at: date.in_time_zone+10.hours, release_remark: "Operação de teste concluída", change_reason: nil, created_at: Time.current, updated_at: Time.current }
    end
    Booking.insert_all!(attributes)
  end
  GC.start
  before_rss = File.read("/proc/self/status")[/^VmRSS:\s+(\d+)/, 1].to_i
  queries = []
  callback = ->(*args) do
    event=ActiveSupport::Notifications::Event.new(*args)
    queries<<event.duration if event.payload[:sql].match?(/\ASELECT\b/) && event.payload[:sql].include?('"bookings"')
  end
  exporter=ExportBookingsXlsx.new(Admin::BookingFilters.new)
  started=Process.clock_gettime(Process::CLOCK_MONOTONIC)
  bytes=nil
  ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { bytes=exporter.call }
  total=Process.clock_gettime(Process::CLOCK_MONOTONIC)-started
  output={ rows: exporter.row_count, total_ms: (total*1000).round(2), query_ms: queries.sum.round(2), queries: queries.size,
    generation_ms: (total*1000-queries.sum).round(2), baseline_rss_mib: (before_rss/1024.0).round(2),
    peak_process_rss_mib: (File.read("/proc/self/status")[/^VmHWM:\s+(\d+)/, 1].to_i/1024.0).round(2), bytes: bytes.bytesize }
  raise "Unexpected record count" unless exporter.row_count==count
  raise "Unexpected queries" unless queries.size==2
  raise ActiveRecord::Rollback
end
raise "Benchmark data was not rolled back" if Booking.where(company: tag).exists?
puts JSON.generate(output)
