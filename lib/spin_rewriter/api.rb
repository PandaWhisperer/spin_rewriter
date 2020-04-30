require 'httparty'

module SpinRewriter
  class Api
    include HTTParty

    class << self
      private

      def tuple(name, keys, values = keys)
        Struct.new(name, *keys.map(&:to_sym)).new(*values.map(&:to_s))
      end
    end

    # URL for invoking the API
    URL = 'http://www.spinrewriter.com/action/api'

    # collection of possible values for the action parameter
    ACTION = tuple('ACTION', ['api_quota', 'text_with_spintax', 'unique_variation',
                 'unique_variation_from_spintax'])

    # collection of possible values for the confidence_level parameter
    CONFIDENCE_LVL = tuple('CONFIDENCE_LVL', ['low', 'medium', 'high'])

    # collection of possible values for the spintax_format parameter
    SPINTAX_FORMAT = tuple('SPINTAX_FORMAT',
      ['pipe_curly', 'tilde_curly', 'pipe_square', 'spin_tag'],
      ['{|}', '{~}', '[|]', '[spin]']
    )

    # collection of all request parameters' names
    REQ_P_NAMES = tuple('REQ_P_NAMES',
      ['email_address', 'api_key', 'action', 'text', 'protected_terms',
       'confidence_level', 'nested_spintax', 'spintax_format'])

    # collection of all response fields' names
    RESP_P_NAMES = tuple('RESP_P_NAMES',
      ['status', 'response', 'api_requests_made', 'api_requests_available',
       'protected_terms', 'confidence_level'])

    # possible response status strings returned by API
    STATUS = tuple('STATUS', ['ok', 'error'], ['OK', 'ERROR'])

    attr_reader :email_address, :api_key

    def initialize(email_address, api_key)
      @email_address = email_address
      @api_key       = api_key
    end

    # Return the number of made and remaining API calls for the 24-hour period.
    # @return: remaining API quota
    # @rtype: dictionary
    def api_quota
      params = {
        REQ_P_NAMES.email_address => self.email_address,
        REQ_P_NAMES.api_key       => self.api_key,
        REQ_P_NAMES.action        => ACTION.api_quota,
      }
      send_request(params)
    end

    # Return processed spun text with spintax.
    #
    # @param text: original text that needs to be changed
    # @type text: string
    # @param protected_terms: (optional) keywords and key phrases that
    #     should be left intact
    # @type protected_terms: list of strings
    # @param confidence_level: (optional) the confidence level of
    #     the One-Click Rewrite process
    # @type confidence_level: string
    # @param nested_spintax: (optional) whether or not to also spin
    #     single words inside already spun phrases
    # @type nested_spintax: boolean
    # @param spintax_format: (optional) spintax format to use in returned text
    # @type spintax_format: string
    # @return: processed text and some other meta info
    # @rtype: dictionary
    def text_with_spintax(text, protected_terms: nil,
                                confidence_level: CONFIDENCE_LVL.medium,
                                nested_spintax: false,
                                spintax_format: SPINTAX_FORMAT.pipe_curly)

      response = transform_plain_text(
        ACTION.text_with_spintax,
        text,
        protected_terms:  protected_terms,
        confidence_level: confidence_level,
        nested_spintax:   nested_spintax,
        spintax_format:   spintax_format
      )

      if response[RESP_P_NAMES.status] == STATUS.error
        raise_error(response)
      else
        response
      end
    end

    private

    # Invoke Spin Rewriter API with given parameters and return its response.
    # @param params: parameters to pass along with the request
    # @type params: tuple of 2-tuples
    # @return: API's response (already JSON-decoded)
    # @rtype: dictionary
    def send_request(params)
      response = self.class.post(URL, body: params)
      response.parsed_response
    end

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

    # Transform plain text using SpinRewriter API.
    #
    # Pack parameters into format as expected by the _send_request method and
    # invoke the action method to get transformed text from the API.
    #
    # @param action: name of the action that will be requested from API
    # @type action: string
    # @param text: text to process
    # @type text: string
    # @param protected_terms: keywords and key phrases that should be left intact
    # @type protected_terms: list of strings
    # @param confidence_level: the confidence level of the One-Click Rewrite
    #     process
    # @type confidence_level: string
    # @param nested_spintax: whether or not to also spin single words inside
    #    already spun phrases
    # @type nested_spintax: boolean
    # @param spintax_format: spintax format to use in returned text
    # @type spintax_format: string
    # @return: processed text and some other meta info
    # @rtype: dictionary
    def transform_plain_text(
        action,
        text,
        protected_terms:,
        confidence_level:,
        nested_spintax:,
        spintax_format:
    )
      if protected_terms
        # protected_terms could be separated by other characters too, like commas
        protected_terms = protected_terms.map { |term| term.encode('utf-8') }.join('\n')
      else
        protected_terms = ''
      end

      params = {
        REQ_P_NAMES.email_address    => self.email_address,
        REQ_P_NAMES.api_key          => self.api_key,
        REQ_P_NAMES.action           => action,
        REQ_P_NAMES.text             => text.encode('utf-8'),
        REQ_P_NAMES.protected_terms  => protected_terms,
        REQ_P_NAMES.confidence_level => confidence_level,
        REQ_P_NAMES.nested_spintax   => nested_spintax,
        REQ_P_NAMES.spintax_format   => spintax_format,
      }

      send_request(params)
    end # def transform_plain_text

  end # class Api
end # module SpinRewriter
