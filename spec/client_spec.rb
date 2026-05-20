require 'spec_helper'

describe Screenshot::Client do
  let(:username) { 'user@example.com' }
  let(:password) { 's3cr3t_api_key' }
  let(:client)   { Screenshot::Client.new(:username => username, :password => password) }
  let(:api_base) { 'https://www.browserstack.com/screenshots' }
  let(:expected_auth) {
    'Basic ' + Base64.encode64("#{username}:#{password}").strip
  }
  # Real BrowserStack job IDs are 40-char hex strings (see API docs:
  # https://www.browserstack.com/screenshots/api). Example pulled from
  # the public docs: "13b93a14db22872fcb5fd1c86b730a51197db319".
  let(:real_job_id) { '13b93a14db22872fcb5fd1c86b730a51197db319' }

  # -------------------------------------------------------------------------
  # Initialization
  # -------------------------------------------------------------------------
  describe '#initialize' do
    it 'requires username and password' do
      expect { Screenshot::Client.new({}) }.to raise_error(RuntimeError, /Expecting Parameters/)
      expect { Screenshot::Client.new(:username => 'u') }.to raise_error(RuntimeError)
      expect { Screenshot::Client.new(:password => 'p') }.to raise_error(RuntimeError)
    end

    it 'symbolizes string keys' do
      c = Screenshot::Client.new('username' => 'u', 'password' => 'p')
      expect(c).to be_a(Screenshot::Client)
    end
  end

  describe 'credential redaction' do
    it '#inspect redacts @authentication' do
      output = client.inspect
      expect(output).to include('[REDACTED]')
      expect(output).not_to include(password)
      expect(output).not_to include(Base64.encode64("#{username}:#{password}").strip)
    end

    it '#to_s redacts @authentication (aliased to inspect)' do
      output = client.to_s
      expect(output).to include('[REDACTED]')
      expect(output).not_to include(password)
    end

    it 'inspect output includes class name and object id format' do
      output = client.inspect
      expect(output).to match(/#<Screenshot::Client:0x[0-9a-f]+/)
    end
  end

  describe 'job_id allowlist' do
    it 'exposes the JOB_ID_FORMAT constant' do
      expect(Screenshot::Client::JOB_ID_FORMAT).to be_a(Regexp)
      expect('abc-123_DEF').to match(Screenshot::Client::JOB_ID_FORMAT)
    end

    it 'accepts the real 40-char hex job_id format from the BrowserStack API' do
      # Sanity check — the production format must pass the allowlist.
      expect(real_job_id).to match(Screenshot::Client::JOB_ID_FORMAT)
    end

    [
      ['screenshots_status', :screenshots_status],
      ['screenshots',        :screenshots],
    ].each do |label, method|
      context "##{label}" do
        # ----- valid IDs accepted -----
        ['abc123', 'abc-123', 'abc_123', 'a' * 64, 'A1b2C3-_'].each do |valid|
          it "accepts #{valid.inspect}" do
            stub_request(:get, "#{api_base}/#{valid}.json")
              .to_return(:status => 200, :body => '{"state":"done","screenshots":[]}')
            expect { client.send(method, valid) }.not_to raise_error
          end
        end

        # ----- invalid IDs rejected before HTTP -----
        bad_inputs = {
          'path traversal'    => '../../v2/account',
          'CRLF'              => "abc\r\nHost: attacker.tld",
          'LF only'           => "abc\nfoo",
          'CR only'           => "abc\rfoo",
          'slash'             => 'abc/def',
          'space'             => 'abc def',
          'dot'               => 'abc.def',
          'too long (65)'     => 'a' * 65,
          'empty'             => '',
          'nil'               => nil,
          'symbol'            => :abc123,
          'integer'           => 123,
          'unicode'           => "abcé",
          'null byte'         => "abc\0def",
          'percent encoded'   => 'abc%2Fdef',
        }
        bad_inputs.each do |label, value|
          it "rejects #{label} (#{value.inspect}) with ArgumentError before HTTP" do
            expect { client.send(method, value) }.to raise_error(ArgumentError, /Invalid job_id/)
            expect(WebMock).not_to have_requested(:get, /browserstack/)
          end
        end
      end
    end
  end

  describe 'parse guard' do
    it 'raises Screenshot::ParseError on an empty 200 body' do
      stub_request(:get, "#{api_base}/abc123.json")
        .to_return(:status => 200, :body => '')
      expect { client.screenshots_status('abc123') }.to raise_error(Screenshot::ParseError)
    end

    it 'raises Screenshot::ParseError on a non-JSON 200 body (HTML maintenance page)' do
      stub_request(:get, "#{api_base}/abc123.json")
        .to_return(:status => 200, :body => '<html>maintenance</html>')
      expect { client.screenshots_status('abc123') }.to raise_error(Screenshot::ParseError)
    end

    it 'raises Screenshot::ParseError when the JSON is a top-level array, not an object' do
      stub_request(:get, "#{api_base}/abc123.json")
        .to_return(:status => 200, :body => '[1,2,3]')
      expect { client.screenshots_status('abc123') }.to raise_error(Screenshot::ParseError)
    end

    it 'ParseError is catchable as StandardError (not bare NoMethodError)' do
      stub_request(:get, "#{api_base}/abc123.json")
        .to_return(:status => 200, :body => '')
      begin
        client.screenshots_status('abc123')
      rescue StandardError => e
        expect(e).to be_a(Screenshot::ParseError)
      end
    end
  end

  describe 'error redaction' do
    secret_body = '{"error":"INTERNAL_TOKEN=abc123xyz"}'

    [
      [401, Screenshot::AuthenticationError,    'authentication'],
      [403, Screenshot::ScreenshotNotAllowedError, 'screenshot not allowed'],
      [422, Screenshot::InvalidRequestError,    'invalid request'],
      [500, Screenshot::UnexpectedError,        'unexpected (5xx)'],
    ].each do |code, exc_class, label|
      context "HTTP #{code} (#{label})" do
        before do
          stub_request(:get, "#{api_base}/abc123.json")
            .to_return(:status => code, :body => secret_body)
        end

        it "raises #{exc_class} with code-only message (no body leak)" do
          begin
            client.screenshots_status('abc123')
            fail 'expected exception'
          rescue exc_class => e
            expect(e.message).to include(code.to_s)
            expect(e.message).not_to include('INTERNAL_TOKEN')
            expect(e.message).not_to include(secret_body)
          end
        end

        it "exposes the response body via opt-in #body reader" do
          begin
            client.screenshots_status('abc123')
            fail 'expected exception'
          rescue exc_class => e
            expect(e.body).to eq(secret_body)
          end
        end

        it "#{exc_class} is still a StandardError (backwards compat)" do
          expect(exc_class.ancestors).to include(StandardError)
        end

        it "#{exc_class} subclasses the new APIError base" do
          expect(exc_class.ancestors).to include(Screenshot::APIError)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # Happy paths
  # -------------------------------------------------------------------------
  describe 'happy paths' do
    it '#screenshots_status returns the state' do
      stub_request(:get, "#{api_base}/abc123.json")
        .with(:headers => {'Authorization' => expected_auth})
        .to_return(:status => 200, :body => '{"state":"done"}')
      expect(client.screenshots_status('abc123')).to eq('done')
    end

    it '#screenshots_done? returns true when state is done' do
      stub_request(:get, "#{api_base}/abc123.json")
        .to_return(:status => 200, :body => '{"state":"done"}')
      expect(client.screenshots_done?('abc123')).to be true
    end

    it '#screenshots_done? returns false when state is pending (real API value)' do
      stub_request(:get, "#{api_base}/abc123.json")
        .to_return(:status => 200, :body => '{"state":"pending"}')
      expect(client.screenshots_done?('abc123')).to be false
    end

    it '#screenshots_status against a realistic 40-char hex job_id' do
      stub_request(:get, "#{api_base}/#{real_job_id}.json")
        .with(:headers => {'Authorization' => expected_auth})
        .to_return(:status => 200, :body => '{"id":"' + real_job_id + '","state":"done","screenshots":[]}')
      expect(client.screenshots_status(real_job_id)).to eq('done')
    end

    it '#screenshots returns the screenshots array' do
      stub_request(:get, "#{api_base}/abc123.json")
        .to_return(:status => 200, :body => '{"screenshots":[{"id":1},{"id":2}]}')
      result = client.screenshots('abc123')
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it '#get_os_and_browsers issues GET /browsers.json and returns the Hash response' do
      # Empirically production returns a Hash (verified by curl). The
      # public API doc claims a top-level array, but reality differs;
      # the client tracks reality.
      body = '{"success":true,"browsers":[' \
        '{"os":"Windows","os_version":"XP","browser":"chrome","browser_version":"21.0"}' \
      ']}'
      stub_request(:get, "#{api_base}/browsers.json")
        .with(:headers => {'Authorization' => expected_auth})
        .to_return(:status => 200, :body => body)
      result = client.get_os_and_browsers
      expect(result).to be_a(Hash)
      expect(result[:success]).to eq(true)
    end

    it '#generate_screenshots POSTs JSON body and returns the job_id' do
      stub_request(:post, "#{api_base}")
        .with(
          :headers => {
            'Authorization' => expected_auth,
            'Content-Type'  => 'application/json'
          }
        )
        .to_return(:status => 200, :body => '{"job_id":"abc123xyz"}')
      expect(client.generate_screenshots(:url => 'https://example.com')).to eq('abc123xyz')
    end
  end

  # -------------------------------------------------------------------------
  # Wire-level safety: ensure unsafe job_ids really do not hit the network
  # -------------------------------------------------------------------------
  describe 'wire-level safety' do
    it 'rejects job_id before issuing any HTTP request (CRLF case)' do
      expect {
        client.screenshots("victim\r\nHost: attacker.tld")
      }.to raise_error(ArgumentError)
      # WebMock.disable_net_connect! plus no stub => any real attempt would
      # raise WebMock::NetConnectNotAllowedError. The fact that we see
      # ArgumentError instead confirms the validation fires first.
      expect(WebMock).not_to have_requested(:any, /.*/)
    end

    it 'rejects job_id before issuing any HTTP request (path traversal case)' do
      expect {
        client.screenshots_status('../../v2/account')
      }.to raise_error(ArgumentError)
      expect(WebMock).not_to have_requested(:any, /.*/)
    end
  end
end
