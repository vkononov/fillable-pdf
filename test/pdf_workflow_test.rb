require_relative 'support/pdf_test_base'

class PdfWorkflowTest < PdfTestBase
  def test_complete_form_filling_workflow # rubocop:disable Minitest/MultipleAssertions
    @pdf.set_fields({ first_name: 'John', last_name: 'Doe', newsletter: 'Yes', language: 'ruby'})

    assert_equal 'John', @pdf.field(:first_name)
    assert_equal 'Doe', @pdf.field(:last_name)
    assert_equal 'Yes', @pdf.field(:newsletter)
    assert_equal 'ruby', @pdf.field(:language)

    @pdf.save_as(@tmp)
    reloaded_pdf = FillablePDF.new(@tmp)

    assert_equal 'John', reloaded_pdf.field(:first_name)
    assert_equal 'Doe', reloaded_pdf.field(:last_name)
  ensure
    reloaded_pdf&.close
  end

  def test_field_manipulation_workflow
    initial_count = @pdf.num_fields

    @pdf.rename_field(:first_name, :given_name)

    assert_equal initial_count, @pdf.num_fields

    @pdf.remove_field(:last_name)

    assert_equal initial_count - 1, @pdf.num_fields

    @pdf.set_field(:given_name, 'Modified')

    assert_equal 'Modified', @pdf.field(:given_name)
  end
end
