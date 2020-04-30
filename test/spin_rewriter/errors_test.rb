require 'test_helper'

module SpinRewriter
  class ErrorsTest < Minitest::Test

    def setup
      @api = Api.new('foo@bar.com', 'test_api_key')
    end

    # Go through all possible error messages and see that they are parsed correctly.
    def test_parsing_error_messages
      msg = 'Authentication with Spin Rewriter API failed.'
      assert_raises(AuthenticationError, msg) do
        @api.send(:raise_error,
          {response: 'Authentication failed. Unique API key is not ' +
            'valid for this user.'})
      end

      assert_raises(AuthenticationError, msg) do
        @api.send(:raise_error,
          {response: 'Authentication failed. No user with this email ' +
            'address found.'})
        end

      assert_raises(AuthenticationError, msg) do
        @api.send(:raise_error,
          {response: 'This user does not have a valid Spin Rewriter ' +
            'subscription.'})
      end

      msg = 'Quota limit for API calls reached.'
      assert_raises(QuotaLimitError, msg) do
        @api.send(:raise_error,
          {response: 'API quota exceeded. You can make 50 requests ' +
            'per day.'})
      end

      msg = 'Not enough time passed since last API request.'
      assert_raises(UsageFrequencyError, msg)  do
        @api.send(:raise_error,
          {response: 'You can only submit entirely new text for ' +
            'analysis once every 5 seconds.'})
      end

      msg = 'Unknown API action requested.'
      assert_raises(UnknownActionError, msg) do
        @api.send(:raise_error,
          {response: 'Requested action does not exist. Please refer ' +
            'to the Spin Rewriter API documentation.'})
      end

      msg = 'Required parameter not present in API request.'
      assert_raises(MissingParameterError, msg) do
        @api.send(:raise_error,
          {response: 'Email address and unique API key are both ' +
            'required. At least one is missing.'})
      end

      msg = 'Invalid parameter value passed to API.'
      assert_raises(ParamValueError, msg) do
        @api.send(:raise_error,{response: 'Original text too short.'})
      end

      assert_raises(ParamValueError, msg) do
        @api.send(:raise_error,
          {response: 'Original text too long. ' +
            'Text can have up to 4,000 words.'})
      end

      assert_raises(ParamValueError, msg) do
        @api.send(:raise_error,
          {response: 'Original text after analysis too long. ' +
            'Text can have up to 4,000 words.'})
      end

      assert_raises(ParamValueError, msg) do
        @api.send(:raise_error,
          {response: 'Spinning syntax invalid. With this action you ' +
           'should provide text with existing valid ' +
           '{first option|second option} spintax.'})
      end

      assert_raises(ParamValueError, msg) do
        @api.send(:raise_error,
          {response: 'The {first|second} spinning syntax invalid. ' +
          'Re-check the syntax, i.e. ' +
          'curly brackets and pipes.'})
      end

      assert_raises(ParamValueError, msg) do
        @api.send(:raise_error,
            {response: 'Spinning syntax invalid.'})
      end

      msg = 'Internal error occured on API server when processing request.'
      assert_raises(InternalApiError, msg) do
        @api.send(:raise_error,
          {response: 'Analysis of your text failed. ' +
            'Please inform us about this.'})
      end

      assert_raises(InternalApiError, msg) do
        @api.send(:raise_error,
          {response: 'Synonyms for your text could not be loaded. ' +
            'Please inform us about this.'})
      end

      assert_raises(InternalApiError, msg) do
        @api.send(:raise_error,
          {response: 'Unable to load your new analyzed project.'})
      end

      assert_raises(InternalApiError, msg) do
        @api.send(:raise_error,
          {response: 'Unable to load your existing analyzed project.'})
      end

      assert_raises(InternalApiError, msg) do
        @api.send(:raise_error,
          {response: 'Unable to find your project in the database.'})
      end

      assert_raises(InternalApiError, msg) do
        @api.send(:raise_error,
          {response: 'Unable to load your analyzed project.'})
      end

      assert_raises(InternalApiError, msg) do
        @api.send(:raise_error, {response: 'One-Click Rewrite failed.'})
      end

      msg = 'Unrecognized API error message received: foo'
      assert_raises(UnknownApiError, msg) do
        @api.send(:raise_error, {response: 'foo'})
      end
    end
  end
end
