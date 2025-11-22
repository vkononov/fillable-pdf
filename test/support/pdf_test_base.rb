require 'test_helper'
require 'tempfile'

class PdfTestBase < Minitest::Test
  def setup
    @original_pdf = 'test/files/filled-out.pdf'
    @temp_pdf = Tempfile.new(['filled-out', '.pdf'], 'test/files')
    FileUtils.cp(@original_pdf, @temp_pdf.path)
    @pdf = FillablePDF.new(@temp_pdf.path)
    @tmp_file = Tempfile.new(['tmp', '.pdf'], 'test/files')
    @tmp = @tmp_file.path
    @base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
  end

  def teardown
    @pdf&.close
    @temp_pdf.close!
    @tmp_file&.close!
  end
end
