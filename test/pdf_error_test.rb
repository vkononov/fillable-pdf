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
    assert_predicate @pdf.num_fields, :positive?
  end
end
