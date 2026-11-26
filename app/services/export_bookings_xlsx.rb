class ExportBookingsXlsx
  LIMIT = 20_000
  MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  class Rejected < StandardError; end
  HEADERS = [
    "Protocolo", "Data de criação", "Hora de criação", "Responsável", "Empresa / Transportadora", "Operação", "Nota fiscal", "Placa", "Modelo do veículo",
    "Data agendada", "Doca", "Janela", "Horário inicial agendado", "Horário final agendado", "Status", "Data do check-in", "Hora do check-in",
    "Data da liberação", "Hora da liberação", "Duração da operação (min)", "Atraso no check-in (min)", "Tempo excedido da janela (min)",
    "Observação da liberação", "Motivo da última alteração", "Data da última atualização", "Hora da última atualização"
  ].freeze
  FIELDS = %i[protocol created_at contact_name company operation invoice plate vehicle_model booking_date dock_number slot_number status checkin_at released_at release_remark change_reason updated_at].freeze
  TEXT_COLUMNS = [ 0, 3, 4, 5, 6, 7, 8, 14, 22, 23 ].freeze
  DATE_COLUMNS = [ 1, 9, 15, 17, 24 ].freeze
  TIME_COLUMNS = [ 2, 12, 13, 16, 18, 25 ].freeze
  WIDTHS = [ 32, 16, 16, 25, 34, 14, 48, 14, 24, 16, 10, 10, 22, 22, 29, 18, 18, 18, 18, 23, 24, 28, 45, 45, 25, 25 ].freeze
  EPOCH = Date.new(1899, 12, 30)
  attr_reader :row_count

  def initialize(filters)
    @filters = filters
    @row_count = 0
  end

  def call
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    raise Rejected, "Os filtros informados são inválidos." unless @filters.valid?
    scope = @filters.scope.except(:limit, :offset, :order)
    @row_count = scope.count
    check_count!
    records = scope.select(*FIELDS).order(:booking_date, :slot_number, :dock_number, :id).limit(LIMIT+1).to_a
    @row_count = records.size
    check_count!
    bytes = build(records).to_stream.read
    log_result(started, "success")
    bytes
  rescue StandardError => error
    log_result(started, "failed", error.class.name)
    raise
  end

  def filename
    values = @filters.query_parameters
    suffix = if values[:start_date].present? && values[:end_date].present?
      "#{Date.iso8601(values[:start_date])}_a_#{Date.iso8601(values[:end_date])}"
    elsif values[:start_date].present?
      "desde_#{Date.iso8601(values[:start_date])}"
    elsif values[:end_date].present?
      "ate_#{Date.iso8601(values[:end_date])}"
    elsif values[:date].present?
      Date.iso8601(values[:date]).iso8601
    else
      "completo_#{Date.current.iso8601}"
    end
    "agendamentos_#{suffix}.xlsx"
  end

  def row(booking)
    created, checkin, released, updated = [ booking.created_at, booking.checkin_at, booking.released_at, booking.updated_at ].map { |time| time&.in_time_zone }
    start = AgendaDefinition.slot_start(booking.booking_date, booking.slot_number)
    finish = AgendaDefinition.slot_end(booking.booking_date, booking.slot_number)
    [ booking.protocol, excel_date(created), excel_time(created), booking.contact_name, booking.company,
      { "entrega"=>"Entrega", "coleta"=>"Coleta" }.fetch(booking.operation), booking.invoice, booking.plate, booking.vehicle_model,
      excel_date(booking.booking_date), booking.dock_number, booking.slot_number, excel_time(start), excel_time(finish),
      Admin::PanelHelper::STATES.fetch(booking.status), excel_date(checkin), excel_time(checkin), excel_date(released), excel_time(released),
      duration(checkin, released), checkin ? [ ((checkin-start)/60).round(2), 0 ].max : nil, released ? [ ((released-finish)/60).round(2), 0 ].max : nil,
      booking.release_remark, booking.change_reason, excel_date(updated), excel_time(updated) ]
  end

  private

  def check_count!
    raise Rejected, "Nenhum agendamento encontrado para os filtros selecionados." if row_count.zero?
    raise Rejected, "A quantidade de agendamentos ultrapassa o limite permitido para exportação. Reduza o período selecionado." if row_count > LIMIT
  end

  def build(records)
    package = Axlsx::Package.new
    workbook = package.workbook
    workbook.date1904 = false
    workbook.use_autowidth = false
    workbook.escape_formulas = true
    header = workbook.styles.add_style(bg_color: "002664", fg_color: "FFFFFF", b: true, alignment: { vertical: :center, wrap_text: true })
    text = workbook.styles.add_style(format_code: "@", alignment: { vertical: :top, wrap_text: true })
    date = workbook.styles.add_style(format_code: "dd/mm/yyyy")
    time = workbook.styles.add_style(format_code: "hh:mm:ss")
    position = workbook.styles.add_style(format_code: "00")
    minutes = workbook.styles.add_style(format_code: "0.00")
    styles = Array.new(26, minutes)
    TEXT_COLUMNS.each { |index| styles[index]=text }
    DATE_COLUMNS.each { |index| styles[index]=date }
    TIME_COLUMNS.each { |index| styles[index]=time }
    [ 10, 11 ].each { |index| styles[index]=position }
    types = Array.new(26, :float)
    TEXT_COLUMNS.each { |index| types[index]=:string }
    [ 10, 11 ].each { |index| types[index]=:integer }
    workbook.add_worksheet(name: "Agendamentos") do |sheet|
      sheet.add_row HEADERS, types: Array.new(26, :string), style: header, height: 36, widths: WIDTHS
      records.each { |booking| sheet.add_row row(booking), types: types, style: styles, widths: WIDTHS }
      sheet.column_widths(*WIDTHS)
      sheet.auto_filter = "A1:Z#{records.size+1}"
      sheet.sheet_view.pane do |pane|
        pane.top_left_cell = "A2"
        pane.state = :frozen
        pane.y_split = 1
        pane.active_pane = :bottom_left
      end
    end
    package
  end

  def excel_date(value)
    value ? (value.to_date-EPOCH).to_i : nil
  end

  def excel_time(value)
    value ? (value.hour*3600+value.min*60+value.sec+value.subsec).to_f/86_400 : nil
  end

  def duration(checkin, released)
    checkin && released && released >= checkin ? ((released-checkin)/60).round(2) : nil
  end

  def log_result(started, result, error_class = nil)
    elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC)-started)*1000).round(2)
    Rails.logger.public_send(result == "success" ? :info : :error, "booking_export at=#{Time.current.iso8601} result=#{result} records=#{row_count} elapsed_ms=#{elapsed} error_class=#{error_class}")
  end
end
