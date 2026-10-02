require_relative 'support/pdf_test_base'

class PdfErrorTest < PdfTestBase
  def test_set_field_with_invalid_key
    err = assert_raises FillablePDF::FieldNotFoundError do
      @pdf.set_field(:invalid_key, 'Value')
    end
    assert_match 'Unknown key name', err.message
  end

  def test_field_with_invalid_key
    err = assert_raises FillablePDF::FieldNotFoundError do
      @pdf.field(:invalid_key)
    end
    assert_match 'Unknown key name', err.message
  end

  def test_field_type_with_invalid_key
    err = assert_raises FillablePDF::FieldNotFoundError do
      @pdf.field_type(:invalid_key)
    end
    assert_match 'Unknown key name', err.message
  end

  def test_continue_after_error
    assert_raises FillablePDF::FieldNotFoundError do
      @pdf.field(:nonexistent)
    end

    @pdf.set_field(:first_name, 'Still Works')

    assert_equal 'Still Works', @pdf.field(:first_name)
  end

  def test_multiple_errors_dont_corrupt_state
    3.times do
      assert_raises FillablePDF::FieldNotFoundError do
        @pdf.field(:nonexistent)
      end
    end

    assert_predicate @pdf, :any_fields?
    assert_predicate @pdf.field_count, :positive?
  end

  def test_save_as_into_missing_directory_raises
    missing_path = File.join(Dir.tmpdir, SecureRandom.uuid, 'out.pdf')

    err = assert_raises(FillablePDF::FileOperationError) { @pdf.save_as(missing_path) }
    assert_match missing_path, err.message
    assert_raises(FillablePDF::FileOperationError) { @pdf.save_as!(missing_path) }
  end

  def test_document_stays_usable_after_failed_save
    @pdf.set_field(:first_name, 'Still Here')
    assert_raises(FillablePDF::FileOperationError) { @pdf.save_as(File.join(Dir.tmpdir, SecureRandom.uuid, 'out.pdf')) }

    @pdf.save_as(@tmp)
    reloaded_pdf = FillablePDF.new(@tmp)

    assert_equal 'Still Here', reloaded_pdf.field(:first_name)
  ensure
    reloaded_pdf&.close
  end
end
