require_relative 'support/pdf_test_base'

class PdfFieldValuesTest < PdfTestBase
  def test_set_field_with_empty_string
    @pdf.set_field(:first_name, '')

    assert_equal '', @pdf.field(:first_name)
  end

  def test_set_field_with_special_characters
    special_text = "Test's \"Quote\" & <tag> \\ backslash"
    @pdf.set_field(:first_name, special_text)

    assert_equal special_text, @pdf.field(:first_name)
  end

  def test_set_field_with_unicode_characters
    unicode_text = '🎉 Hello 世界 Привет مرحبا'
    @pdf.set_field(:first_name, unicode_text)

    assert_equal unicode_text, @pdf.field(:first_name)
  end

  def test_that_an_asian_font_works
    @pdf.set_field(:first_name, '理查德')

    assert_equal '理查德', @pdf.field(:first_name)
  end

  def test_set_field_with_long_text
    long_text = 'A' * 1000
    @pdf.set_field(:first_name, long_text)

    assert_equal long_text, @pdf.field(:first_name)
  end

  def test_set_field_with_newlines_and_tabs
    text_with_whitespace = "Line 1\nLine 2\tTabbed"
    @pdf.set_field(:first_name, text_with_whitespace)

    assert_equal text_with_whitespace, @pdf.field(:first_name)
  end

  def test_set_field_with_numeric_value
    @pdf.set_field(:first_name, 12_345)

    assert_equal '12345', @pdf.field(:first_name)
  end
end
