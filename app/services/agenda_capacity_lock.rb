require "digest"

class AgendaCapacityLock
  def self.lock!(date:, dock_number:, slot_number:)
    acquire("position:#{date.iso8601}:#{Integer(dock_number.to_s, 10)}:#{Integer(slot_number.to_s, 10)}")
  end

  def self.lock_positions!(positions)
    positions.uniq.sort_by { |position| [ position.fetch(:date).iso8601, position.fetch(:dock_number), position.fetch(:slot_number) ] }.each do |position|
      lock!(**position)
    end
  end

  def self.lock_dock!(dock_number:)
    acquire("physical-dock:#{Integer(dock_number.to_s, 10)}")
  end

  def self.lock_request!(request_id)
    acquire("request:#{request_id}")
  end

  def self.lock_user_management!
    acquire("user-management")
  end

  def self.acquire(resource)
    connection = ApplicationRecord.connection
    raise ArgumentError, "Agenda lock requires a transaction" unless connection.transaction_open?

    connection.execute("SET LOCAL lock_timeout = '5s'")
    key = Digest::SHA256.digest("dsv-agenda:v1:#{resource}").unpack1("q>")
    bind = ActiveRecord::Relation::QueryAttribute.new("key", key, ActiveRecord::Type::Integer.new(limit: 8))
    connection.exec_query("WITH acquired AS MATERIALIZED (SELECT pg_advisory_xact_lock($1::bigint)) SELECT 1 FROM acquired",
      "Agenda capacity lock", [ bind ])
  end
  private_class_method :acquire
end
