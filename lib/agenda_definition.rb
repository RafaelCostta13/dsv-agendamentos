module AgendaDefinition
  DOCK_NUMBERS = (1..8).freeze
  DOCK_NUMBERS_BY_OPERATION = {
    "entrega" => (1..3).freeze,
    "coleta" => (4..8).freeze
  }.freeze
  SLOT_NUMBERS = (1..10).freeze
  SLOT_WINDOWS = {
    1 => [ "08:00", "09:00" ].freeze,
    2 => [ "09:00", "10:00" ].freeze,
    3 => [ "10:00", "11:00" ].freeze,
    4 => [ "11:00", "12:00" ].freeze,
    5 => [ "12:00", "13:00" ].freeze,
    6 => [ "13:00", "14:00" ].freeze,
    7 => [ "14:00", "15:00" ].freeze,
    8 => [ "15:00", "16:00" ].freeze,
    9 => [ "16:00", "17:00" ].freeze,
    10 => [ "17:00", "17:48" ].freeze
  }.freeze

  def self.permitted_date?(date, now: Time.current)
    date.is_a?(Date) && (now.to_date..now.to_date + 2).cover?(date)
  end

  def self.dock_numbers_for(operation)
    DOCK_NUMBERS_BY_OPERATION.fetch(operation.to_s, [])
  end

  def self.future_slot?(date, number, now: Time.current)
    permitted_date?(date, now: now) && SLOT_NUMBERS.cover?(number) && slot_start(date, number) > now
  end

  def self.slot_end(date, number)
    hour, minute = SLOT_WINDOWS.fetch(number).last.split(":").map(&:to_i)
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end

  def self.slot_start(date, number)
    hour, minute = SLOT_WINDOWS.fetch(number).first.split(":").map(&:to_i)
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end

  def self.checkin_cutoff(date)
    Time.zone.local(date.year, date.month, date.day, 17, 30)
  end

  def self.no_show_date_limit(now: Time.current)
    now >= checkin_cutoff(now.to_date) ? now.to_date : now.to_date - 1
  end
end
