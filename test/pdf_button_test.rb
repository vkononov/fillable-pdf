require_relative 'support/pdf_test_base'

class PdfButtonTest < PdfTestBase
  def test_that_a_checkbox_can_be_checked_and_unchecked
    @pdf.set_field(:nascar, 'Yes')

    assert_equal 'Yes', @pdf.field(:nascar)
    @pdf.set_field(:newsletter, 'Off')

    assert_equal 'Off', @pdf.field(:newsletter)
  end

  def test_that_a_radio_button_can_be_checked_and_unchecked
    @pdf.set_field(:language, 'ruby')

    assert_equal 'ruby', @pdf.field(:language)
    @pdf.set_field(:language, 'Off')

    assert_equal 'Off', @pdf.field(:language)
  end

  def test_checkbox_toggle_multiple_times
    @pdf.set_field(:nascar, 'Yes')

    assert_equal 'Yes', @pdf.field(:nascar)

    @pdf.set_field(:nascar, 'Off')

    assert_equal 'Off', @pdf.field(:nascar)

    @pdf.set_field(:nascar, 'Yes')

    assert_equal 'Yes', @pdf.field(:nascar)
  end

  def test_radio_button_change_options_multiple_times
    @pdf.set_field(:language, 'ruby')

    assert_equal 'ruby', @pdf.field(:language)

    @pdf.set_field(:language, 'python')

    assert_equal 'python', @pdf.field(:language)

    @pdf.set_field(:language, 'dart')

    assert_equal 'dart', @pdf.field(:language)
  end
end
