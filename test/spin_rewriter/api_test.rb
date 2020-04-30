require 'test_helper'

module SpinRewriter
  class ApiTest < MiniTest::Test

    def setup
      @api = Api.new('foo@bar.com', 'test_api_key')
    end

    # Test initialization of Api.
    # Api is initialized on every test run and stored as self.sr.
    # We just need to test stored values.
    def test_init
      assert_equal @api.email_address, 'foo@bar.com'
      assert_equal @api.api_key, 'test_api_key'
    end

    # Test that _send_requests correctly parses JSON response into a dict
    # and that request parameters get encoded beforehand.
    def test_send_request
      stub_response({ foo: "bär" }) do
        result = @api.send(:send_request, { foo: 'bär' })

        assert_equal 'bär', result['foo']
      end
    end

    # Test if Api.api_quota() correctly parses the response it gets from SpinRewriter API.
    def test_api_quota
      msg = 'You made 0 API requests in the last 24 hours. 100 still available.'

      mocked_response = {
        "status" => "OK",
        "api_requests_made" => 0,
        "api_requests_available" => 100,
        "response" => msg
      }

      stub_response(mocked_response) do
        result = @api.api_quota

        assert_equal 'OK', result['status']
        assert_equal 0,    result['api_requests_made']
        assert_equal 100,  result['api_requests_available']
        assert_equal msg,  result['response']
      end
    end

    # Test if Api.text_with_spintax() correctly parses the response it
    # gets from SpinRewriter API.
    def test_text_with_spintax
      text      = 'This is my über cute dog.'
      spun_text = 'This is my über cute {dog|pet|animal}.'

      mocked_response = {
        "status"                 => "OK",
        "response"               => spun_text,
        "api_requests_made"      => 1,
        "api_requests_available" => 99,
        "protected_terms"        => "food, cat",
        "nested_spintax"         => "false",
        "confidence_level"       => "medium"
      }

      stub_response(mocked_response) do
        result = @api.text_with_spintax(text, protected_terms: ['food', 'cat'])

        assert_equal 'OK',        result['status']
        assert_equal 1,           result['api_requests_made']
        assert_equal 99,          result['api_requests_available']
        assert_equal 'food, cat', result['protected_terms']
        assert_equal 'false',     result['nested_spintax']
        assert_equal 'medium',    result['confidence_level']
        assert_equal spun_text,   result['response']
      end
    end

    # Test if Api.unique_variation() correctly parses the response it
    # gets from SpinRewriter API.
    def test_unique_variation
      text      = 'This is my über cute dog.'
      spun_text = 'This is my über cute pet.'

      mocked_response = {
        "status"                 => "OK",
        "response"               => spun_text,
        "api_requests_made"      => 2,
        "api_requests_available" => 98,
        "protected_terms"        => "food, cat",
        "nested_spintax"         => "false",
        "confidence_level"       => "medium"
      }

      stub_response(mocked_response) do
        result = @api.unique_variation(text, protected_terms: ['food', 'cat'])

        assert_equal 'OK',        result['status']
        assert_equal 2,           result['api_requests_made']
        assert_equal 98,          result['api_requests_available']
        assert_equal 'food, cat', result['protected_terms']
        assert_equal 'false',     result['nested_spintax']
        assert_equal 'medium',    result['confidence_level']
        assert_equal spun_text,   result['response']
      end
    end

    # Test if Api.unique_variation_from_spintax() correctly parses the
    # response it gets from SpinRewriter API.
    def test_unique_variation_from_spintax
      text      = 'This is my über cute [dog|pet|animal].'
      spun_text = 'This is my über cute animal.'

      mocked_response = {
        "status"                 => "OK",
        "response"               => spun_text,
        "api_requests_made"      => 2,
        "api_requests_available" => 98,
        "confidence_level"       => "medium"
      }
      stub_response(mocked_response) do
        result = @api.unique_variation_from_spintax(text,
          nested_spintax: false,
          spintax_format: Api::SPINTAX_FORMAT.pipe_square
        )

        # test results
        assert_equal 'OK',        result['status']
        assert_equal 2,           result['api_requests_made']
        assert_equal 98,          result['api_requests_available']
        assert_equal 'medium',    result['confidence_level']
        assert_equal spun_text,   result['response']
      end
    end

    # Test if Api.transform_plain_text() correctly parses the response it
    # gets from SpinRewriter API. This method is used by unique_variation()
    # and text_with_spintax().
    def test_transform_plain_text
      text      =
      spun_text = 'This is my über cute pet.'

      mocked_response = {
        "status"                 => "OK",
        "response"               => spun_text,
        "api_requests_made"      => 3,
        "api_requests_available" => 97,
        "protected_terms"        => "",
        "nested_spintax"         => "false",
        "confidence_level"       => "medium"
      }

      stub_response mocked_response do
        result = @api.send(:transform_plain_text,
          Api::ACTION.unique_variation, text,
          protected_terms:  [],
          confidence_level: Api::CONFIDENCE_LVL.medium,
          nested_spintax:   false,
          spintax_format:   Api::SPINTAX_FORMAT.pipe_curly,
        )

        assert_equal 'OK',        result['status']
        assert_equal 3,           result['api_requests_made']
        assert_equal 97,          result['api_requests_available']
        assert_equal '',          result['protected_terms']
        assert_equal 'false',     result['nested_spintax']
        assert_equal 'medium',    result['confidence_level']
        assert_equal spun_text,   result['response']
      end
    end
    #
    # @mock.patch('spinrewriter.Api._send_request')
    # def test_protected_terms_transformation(self, _send_request):
    #   """Test that protected_terms are correctly transformed into
    #   a string."""
    #   # prepare arguments for calling _transform_plain_text
    #   args = dict(
    #       action=Api.ACTION.unique_variation,
    #       text=u'This is my über tasty pet food.',
    #       protected_terms=['food', 'cat'],
    #       confidence_level=Api.CONFIDENCE_LVL.medium,
    #       nested_spintax=False,
    #       spintax_format=Api.SPINTAX_FORMAT.pipe_curly,
    #   )
    #
    #   # we don't care what the response is
    #   _send_request.return_value = None
    #
    #   # call it
    #   @api._transform_plain_text(**args)
    #
    #   # now test that protected_terms are in correct format
    #   _send_request.assert_called_with((
    #       ('email_address', 'foo@bar.com'),
    #       ('api_key', 'test_api_key'),
    #       ('action', 'unique_variation'),
    #       ('text', u'This is my über tasty pet food.'.encode('utf-8')),
    #       # This is the only line we are interested in here,
    #       # it needs to be newline-separated
    #       ('protected_terms', 'food\ncat'),
    #       ('confidence_level', 'medium'),
    #       ('nested_spintax', False),
    #       ('spintax_format', '{|}'),
    #   ))
    # end
    #
    # @mock.patch('spinrewriter.Api._send_request')
    # def test_protected_terms_empty(self, _send_request):
    #   """Test that correct default value is set for protected_terms if the
    #   list is empty.
    #   """
    #   # prepare arguments for calling _transform_plain_text
    #   args = dict(
    #       action=Api.ACTION.unique_variation,
    #       text=u'This is my über cute dog.',
    #       protected_terms=[],
    #       confidence_level=Api.CONFIDENCE_LVL.medium,
    #       nested_spintax=False,
    #       spintax_format=Api.SPINTAX_FORMAT.pipe_curly,
    #   )
    #
    #   # we don't care what the response is
    #   _send_request.return_value = None
    #
    #   # call it
    #   @api._transform_plain_text(**args)
    #
    #   # now test that protected_terms are in correct format
    #   _send_request.assert_called_with((
    #       ('email_address', 'foo@bar.com'),
    #       ('api_key', 'test_api_key'),
    #       ('action', 'unique_variation'),
    #       ('text', u'This is my über cute dog.'.encode('utf-8')),
    #       # This is the only line we are interested in here,
    #       # it needs to be an empty string, not an empty list
    #       ('protected_terms', ''),
    #       ('confidence_level', 'medium'),
    #       ('nested_spintax', False),
    #       ('spintax_format', '{|}'),
    #   ))
    # end
    #
    def test_unique_variation_from_spintax_error
      # mock response from SpinRewriter
      mocked_response = {
        "status"   => "ERROR",
        "response" => "Authentication failed. Unique API key is not valid for this user."
      }

      stub_response(mocked_response) do
        assert_raises(AuthenticationError) do
          @api.unique_variation_from_spintax('This is my dog.')
        end
      end
    end

    private

    def stub_response(body, &block)
      response = Minitest::Mock.new
      response.expect :body, JSON.dump(body)

      @api.class.stub :post, response, &block

      response.verify
    end

  end # class ApiTest
end # module SpinRewriter
