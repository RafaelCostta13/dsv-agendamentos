require "roo"
require "zip"
require "tempfile"

module XlsxReader
  def with_xlsx(bytes)
    Tempfile.create([ "export", ".xlsx" ]) do |file|
      file.binmode
      file.write(bytes)
      file.flush
      book = Roo::Excelx.new(file.path)
      begin
        yield book
      ensure
        book.close
      end
    end
  end

  def xlsx_xml(bytes, path = "xl/worksheets/sheet1.xml")
    document = nil
    Zip::File.open_buffer(bytes) { |zip| document = Nokogiri::XML(zip.read(path)).remove_namespaces! }
    document
  end
end
