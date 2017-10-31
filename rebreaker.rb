require 'watir'
require 'byebug'
require 'unirest'

class Rebreaker
  DIGITS_DICT = {
    'zero' => '0',
    'one' => '1',
    'two' => '2',
    'three' => '3',
    'four' => '4',
    'five' => '5',
    'six' => '6',
    'seven' => '7',
    'eight' => '8',
    'nine' => '9'
  }.freeze

  WIDGET = ".//iframe[@title='recaptcha widget']".freeze
  RECAPTCHA_CHALLENGE = ".//iframe[@title='recaptcha challenge']".freeze
  AUDIO_BUTTON = ".//*[@id='recaptcha-audio-button']".freeze
  AUDIO_BUTTON_DOWNLOAD = ".//a[@class='rc-audiochallenge-download-link']".freeze

  def initialize(browser)
    @browser = browser
  end

  def challenge
    puts 'search and click ReCaptcha widget'
    search_and_click WIDGET
    @recaptcha = @browser.iframe(xpath: RECAPTCHA_CHALLENGE)
    puts 'search recaptcha audio challenge'
    wait_for { audio_challenge.exists? }
    puts 'search and click audio button'
    audio_challenge.click
  end

  def audio_challenge
    @recaptcha.button(id: 'recaptcha-audio-button')
  end

  def extract_audio
    puts 'extract audio url'
    url = search(AUDIO_BUTTON_DOWNLOAD, @recaptcha).attribute_value('href')
    puts 'Download audio'
    response = Unirest.get(url) 
    save_audio_file response
  end

  def save_audio_file(res)
    dir = './audio.mp3' # TODO: Change to temp directory?
    dirname = File.dirname(dir)
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    puts "Write audio file at #{dir}"
    File.open(dir, 'wb') { |f| f.write(res.body) }
  end

  def solve
    puts 'search Challenge'
    challenge
    puts 'Extract audio'
    extract_audio
  end

  private

  def search_and_click(xpath, source = nil)
    element = search(xpath, source)
    element.click
    element
  end

  def search(xpath, source = nil)
    source ||= @browser
    wait_for { source.element(xpath: xpath).exists? }
    source.element(xpath: xpath)
  end

  def wait_for(timeout = 20)
    return unless block_given?
    begin
      Watir::Wait.until(timeout) { yield }
    rescue => e
      puts e
    end
  end
end

# Test
RECAPTCHA_PAGE_URL = 'https://www.google.com/recaptcha/api2/demo'.freeze
browser = Watir::Browser.new :chrome
sleep 2
browser.goto RECAPTCHA_PAGE_URL
sleep 2

rebreaker = Rebreaker.new(browser)

# solve recaptcha
rebreaker.solve
