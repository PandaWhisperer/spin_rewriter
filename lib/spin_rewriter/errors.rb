module SpinRewriter

  # Base class for exceptions in Spin Rewriter module.
  class ApiError < StandardError
    attr_reader :api_error_msg

    def initialize(api_error_msg)
      super
      # api_error_msg respresents raw error string as returned by API server
      @api_error_msg = api_error_msg
    end
  end


  # Raised when authentication error occurs.
  class AuthenticationError < ApiError
    def message
      'Authentication with Spin Rewriter API failed.'
    end
  end


  # Raised when API quota limit is reached.
  class QuotaLimitError < ApiError
    def message
      'Quota limit for API calls reached.'
    end
  end


  # Raised when subsequent API requests are made in a too short time interval.
  class UsageFrequencyError < ApiError
    def message
      'Not enough time passed since last API request.'
    end
  end


  # Raised when unknown API action is requested.
  class UnknownActionError < ApiError
    def message
      'Unknown API action requested.'
    end
  end


  # Raised when required parameter is not provided.
  class MissingParameterError < ApiError
    def message
      'Required parameter not present in API request.'
    end
  end


  # Raised when parameter passed to API call has an invalid value.
  class ParamValueError < ApiError
    def message
      'Invalid parameter value passed to API.'
    end
  end


  # Raised when unexpected error occurs on the API server when processing a request.
  class InternalApiError < ApiError
    def message
      'Internal error occured on API server when processing request.'
    end
  end


  # Raised when API call results in an unrecognized error.
  class UnknownApiError < ApiError
    def message
      "Unrecognized API error message received: #{api_error_msg}"
    end
  end

end
