require_relative 'support/pdf_test_base'

class PdfValidationTest < PdfTestBase
  def test_set_field_with_nil_value
    err = assert_raises FillablePDF::InvalidArgumentError do
      @pdf.set_field(:first_name, nil)
    end
    assert_match 'Field value cannot be nil', err.message
  end

  def test_set_field_with_invalid_key_type
    err = assert_raises FillablePDF::InvalidArgumentError do
      @pdf.set_field(12_345, 'Value')
    end
    assert_match 'Field name must be a string or symbol', err.message
  end

  def test_set_field_with_array_as_key
    err = assert_raises FillablePDF::InvalidArgumentError do
      @pdf.set_field([:first_name], 'Value')
    end
    assert_match 'Field name must be a string or symbol', err.message
  end
end
