class Check_MK
  require 'json'
  require 'uri'
  require 'net/http'
  require 'pp'

  require_relative 'check_mk/folder'
  require_relative 'check_mk/wato'

  # Create a top-level object.
  # [+uri+] the URI to the check_mk web interface
  # [+user+] the username to login with
  # [+password+] the password to login with
  # [+confdir+] the base of the WATO configuration directory
  def initialize(uri, user, password, confdir = '')
    @uri = uri
    @user = user
    @password = password
    @confdir = confdir
    #TODO:@wato = Check_MK::Wato.new(@confdir)
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
    raise ArgumentError, 'host already exists' if host_exists?(name, folder)
    params = {
      filled_in: 'edithost',
      _transid: '-1',
      host: name,
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
    raise ArgumentError, 'host does not exist' unless host_exists?(name, folder)
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
    # XXX-FIXME: check security of name
    # FIXME: use wato instead of this?
    system "cmk -I #{name}"
    system "cmk --reload"
  end

  def activate
    http_request(@uri + '/wato_ajax_activation.py', {})
  end

  private

  # Return true if a host exists
  def host_exists?(host, folder = '')
    list_hosts(folder).include? host
  end

  def http_request(request_uri, params = nil, debug = false)
    uri = URI.parse(request_uri)
    unless params.nil?
      params.merge!({ _username: @user, _secret: @password})
      uri.query = URI.encode_www_form(params)
    end
    http = Net::HTTP.new(uri.host, uri.port)
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
