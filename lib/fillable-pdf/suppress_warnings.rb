class FillablePDF
  module SuppressWarnings
    def suppress_warnings
      original_verbosity = $VERBOSE
      $VERBOSE = nil
      result = yield
      $VERBOSE = original_verbosity
      result
    end
  end
end
