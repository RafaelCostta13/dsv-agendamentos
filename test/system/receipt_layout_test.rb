require "test_helper"
require "puma"
require "open3"
require "timeout"
require_relative "../support/booking_data"

class ReceiptLayoutTest < ActiveSupport::TestCase
  include BookingData

  test "the shared receipt remains readable and square at all eight requested viewport widths" do
    booking = Booking.create!(booking_attributes(booking_date: Date.current+1, protocol: "DA-#{'A'*47}", company: "Transportadora com nome extenso "*3))
    receipt = BookingsController.render(template: "bookings/confirmation", assigns: { booking: booking }, layout: "application")
    png = ReceiptQrCode.new(booking).png
    widths = [ 320, 375, 390, 414, 430, 768, 1024, 1440 ]
    frames = widths.map { |width| "<iframe src='/receipt' style='border:0;width:#{width}px;height:1800px' data-width='#{width}'></iframe>" }.join
    harness = <<~HTML
      <!doctype html><meta charset="utf-8">#{frames}<pre id="results">RUNNING</pre>
      <script>window.addEventListener('load',()=>{
        const results=[...document.querySelectorAll('iframe')].map(frame=>{
          const page=frame.contentDocument,w=frame.contentWindow;
          const image=page.querySelector('.receipt-qr img'),box=image.getBoundingClientRect();
          return {width:w.innerWidth,expected:Number(frame.dataset.width),overflow:page.documentElement.scrollWidth>w.innerWidth,
            loaded:image.complete&&image.naturalWidth>0,square:Math.abs(box.width-box.height)<1,size:box.width,
            protocol:page.querySelector('.protocol').textContent};
        });document.querySelector('#results').textContent=JSON.stringify(results);
      });</script>
    HTML
    app = ->(env) do
      case env["PATH_INFO"]
      when "/layout-test" then [ 200, { "content-type"=>"text/html" }, [ harness ] ]
      when "/receipt" then [ 200, { "content-type"=>"text/html" }, [ receipt ] ]
      when "/agendar/confirmacao.png" then [ 200, { "content-type"=>"image/png" }, [ png ] ]
      else Rails.application.call(env)
      end
    end
    server = Puma::Server.new(app, nil, min_threads: 1, max_threads: 3)
    server.add_tcp_listener("127.0.0.1", 0)
    port=server.binder.ios.first.addr[1]
    server.run
    output, status=Timeout.timeout(30) do
      Open3.capture2e(ENV.fetch("CHROMIUM_BIN", "/usr/bin/chromium"), "--headless", "--no-sandbox", "--disable-dev-shm-usage", "--disable-background-networking", "--virtual-time-budget=3000", "--dump-dom", "http://127.0.0.1:#{port}/layout-test")
    end
    assert status.success?
    node=Nokogiri::HTML(output).at_css("#results")
    assert node, output.lines.last(5).join
    results=JSON.parse(node.text)
    assert_equal widths, results.map { |row| row["width"] }
    results.each do |row|
      assert_equal row["expected"], row["width"]
      assert_not row["overflow"], row.inspect
      assert row["loaded"], row.inspect
      assert row["square"], row.inspect
      assert row["size"].between?(180, 240), row.inspect
      assert_equal booking.protocol, row["protocol"]
    end
  ensure
    server&.stop(true)
  end
end
