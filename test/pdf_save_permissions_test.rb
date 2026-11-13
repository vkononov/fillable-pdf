require_relative 'support/pdf_test_base'

class PdfSavePermissionsTest < PdfTestBase
  def test_save_preserves_existing_permissions_and_content
    path = @temp_pdf.path
    File.chmod(0o640, path)
    @pdf.set_field(:first_name, 'Private')
    @pdf.save

    assert_equal 0o640, File.stat(path).mode & 0o777
    reloaded = FillablePDF.new(path)

    assert_equal 'Private', reloaded.field(:first_name)
  ensure
    reloaded&.close
  end
end
