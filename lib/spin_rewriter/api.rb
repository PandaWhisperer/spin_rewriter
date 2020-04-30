module SpinRewriter
  class Api
    # RESP_P_NAMES = %i[status response api_requests_made api_requests_available
    #                   protected_terms confidence_level]

    def initialize(username, api_key)
    end

    private

    # Examine the API response and raise exception of the appropriate type.
    # NOTE: usage of this method only makes sense when API response's status
    # indicates an error
    # @param api_response: API's response fileds
    # :type api_response: dictionary
    def raise_error(api_response)
      error_msg = api_response[:response]

      case error_msg
      when %r{Authentication failed. No user with this email address found.}i,
           %r{Authentication failed. Unique API key is not valid for this user.}i,
           %r{This user does not have a valid Spin Rewriter subscription.}i
        raise AuthenticationError, error_msg

      when %r{API quota exceeded. You can make \d+ requests per day.}i
        raise QuotaLimitError, error_msg

      when %r{You can only submit entirely new text for analysis once every \d+ seconds.}i
        raise UsageFrequencyError, error_msg

      when %r{Requested action does not exist.}i
        # NOTE: This should never occur unless
        # there is a bug in the API library.
        raise UnknownActionError, error_msg

      when %r{Email address and unique API key are both required.}i
        # NOTE: This should never occur unless
        # there is a bug in the API library.
        raise MissingParameterError, error_msg

      when %r{Original text too short.}i,
           %r{Original text too long. Text can have up to 4,000 words.}i,
           %r{Original text after analysis too long. Text can have up to 4,000 words.}i,
           %r{
             Spinning syntax invalid.
             With this action you should provide text with existing valid'
             {first option|second option} spintax.
           }ix,
           %r{
             The {first|second} spinning syntax invalid.
             Re-check the syntax, i.e. curly brackets and pipes\.
           }ix,
           %r{Spinning syntax invalid.}i
        raise ParamValueError, error_msg

      when
        %r{Analysis of your text failed. Please inform us about this.}i,
        %r{Synonyms for your text could not be loaded. Please inform us about this.}i,
        %r{Unable to load your new analyzed project.}i,
        %r{Unable to load your existing analyzed project.}i,
        %r{Unable to find your project in the database.}i,
        %r{Unable to load your analyzed project.}i,
        %r{One-Click Rewrite failed.}i
        raise InternalApiError, error_msg

      else
        raise UnknownApiError, error_msg
      end # case
    end # def _raise_error

  end # class Api
end # module SpinRewriter
