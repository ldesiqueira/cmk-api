class Check_MK
  require 'awesome_print'
  require 'logger'
  require 'json'
  require 'resolv'
  require 'uri'
  require 'net/http'
  require 'pp'

  require_relative 'check_mk/folder'
  require_relative 'check_mk/wato'

  attr_accessor :log

  # Create a top-level object.
  # Keyword arguments are:
  # [+uri+] the URI to the check_mk web interface
  # [+user+] the username to login with
  # [+password+] the password to login with
  # [+confdir+] the base of the WATO configuration directory
  # [+site+] The name of the OMD site
  # [+logger+] A logging object compatible with the Logger class
  def initialize(opt)
    raise ArgumentError unless opt.kind_of? Hash
    @config = {
      confdir: File.dirname(__FILE__) + '/../etc',
      logger: Logger.new('/dev/null'),
      site: nil,
    }.merge(opt)
 
    @log = @config[:logger]
    @log.level = Logger::DEBUG
    @log.debug "starting log"

    check_sanity
    @config.each { |k,v| instance_variable_set("@#{k}", v) }

    #TODO:@wato = Check_MK::Wato.new(@confdir)
  end

  # Check the sanity of the environment and the configuration settings
  def check_sanity
    errors = []
    [:site, :uri, :user, :password, :confdir].each do |sym|
      if @config[sym].nil?# or @config[sym].empty?
        errors << "Option '#{sym}' is required"
      end
    end
    unless errors.empty?
      $stderr.puts 'ERROR: The following problems were detected:'
      errors.map { |e| $stderr.puts " * #{e}" }
      $stderr.puts "\nConfiguration options:\n"
      ap @config
      exit 1
    end
  end

  # Get a handle to a folder
  # [+name+] the name of the folder. An empty string means the top-level folder
  def folder(name)
    Check_MK::Folder.new(self, name)
  end

  # Add a host to a folder
  # [+name+] the name of the host
  # [+folder+] the name of the folder
  # [+options+] additional options, such as tags
  def add_host(name, folder = '', options = {})
    raise ArgumentError, 'host already exists' if host_exists?(name)
    
    # Lookup the IP address of the FQDN
    # TODO: catch the exception if it doesn't exist
    in_addr = Resolv.getaddress(name)
    
    params = {
      filled_in: 'edithost',
      _transid: '-1',
      host: name,
      _change_ipaddress: 'on',
      attr_ipaddress: in_addr,
      attr_tag_agent: 'cmk-agent%7Ctcp',
      attr_tag_networking: 'lan',
      save: 'Save+%26+Finish',
      folder: folder,
      mode: 'newhost',
      _do_confirm: 'yes',
      _do_actions: 'yes',
      }
    params.merge! options

    response = http_request(@uri + '/wato.py', params)
    raise 'An error occured' if response =~ /div class=error/
  end

  def delete_host(name, folder = '')
    raise ArgumentError, 'host does not exist' unless host_exists?(name)
    response = http_request(@uri + '/wato.py', {
    	mode: 'folder',
	_delete_host: name,
	_transid: '-1',
	folder: folder,
	_do_confirm: 'yes',
	_do_actions: 'yes',
    })
    raise 'An error occured' if response =~ /div class=error/
  end

  def get_host(name, folder = '')
    result = {
       name: name,
       has_services: has_services(name)
    }
  end

  def has_services(name)
    result = `#{cmk} --dump #{name} | sed -e '1,/------/d' | wc -l`.to_i
    return (result > 0)
  end

  # Return a list of all hosts
  def hosts
    `#{cmk} --list-hosts`.split(/\n/).sort
  end

  # Return a list of the hosts in a given folder
  # [+folder+] the name of the folder
  def list_hosts(folder = '')
    rows = JSON.parse(http_request(@uri + '/view.py', {
        wato_folder: folder,
	search: 'Search',
	filled_in: 'filter',
	host_address_prefix: 'yes',
	view_name: 'searchhost',
	output_format: 'json',
	}))
    rows.shift  # skip the header
    rows.map { |r| r[1] }
  end

  # Return a list of folders
  def folders
    html = http_request(@uri + '/wato.py', {
       folder: '',
       mode: 'folder',
       }, false)
    html.split(/\n/).each do |line|
       next unless line =~ /class="folderpath"/
    end
    res = []
    html.split(/\n/).grep(/mode=editfolder/).each do |line|
      line =~ /folder=(.*?)'/
      res.push $1 unless $1.nil?
    end
    res
  end

  def inventory_host(name)
    # TODO: use wato instead of this?
    system "#{cmk} -I #{validate_hostname(name)}"
    activate   # TODO: remove this in the next API version
  end

  def reinventory_host(name)
    system "#{cmk} -II #{validate_hostname(name)}"
  end

  def activate
    log.info 'activating changes'
    result = `#{cmk} --reload 2>&1`
    log.debug result
    logfile = ENV['HOME'] + '/var/check_mk/wato/log/pending.log'
    if File.exists? logfile
      log.debug "deleting #{ logfile }"
      File.unlink logfile
    else
      log.warn "file not found: #{ logfile }"
    end

    #DEADWOOD: this sometimes times out with 502 HTTP errors when the
    #          server is heavily loaded
    #response = http_request(@uri + '/wato_ajax_activation.py', {})
    #unless response =~ /div class=act_success/
    #  log.error 'activation failed'
    #  log.debug response
    #  raise 'activation failed'
    #end
  end

  private

  # Ensure that [+userdata+] is a valid hostname. 
  def validate_hostname(userdata)
    if userdata =~ /\A[A-Za-z0-9.]{2,254}\z/
      userdata
    else
      raise 'Illegal hostname'
    end
  end

  # Return the path to the check_mk 'cmk' binary
  def cmk
   if ENV['USER'] == @site
     "/omd/sites/#{@site}/bin/cmk"
   else
     "sudo -i -u #{@site} /omd/sites/#{@site}/bin/cmk"
   end
  end

  # Return true if a host exists
  def host_exists?(host)
    `#{cmk} --list-hosts`.split(/\n/).include?(host)
  end

  def http_request(request_uri, params = nil, debug = false)
    uri = URI.parse(request_uri)
    unless params.nil?
      params.merge!({ _username: @user, _secret: @password})
      uri.query = URI.encode_www_form(params)
    end
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 300
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@user, @password)
    response = http.request(request)
    if debug
      puts "uri: " + uri.to_s
      pp response
      puts response.body
    end
    response.body
  end
end
