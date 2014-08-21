class Check_MK
  require 'uri'
  require 'net/http'
  require 'pp'

  # Add a host to a folder
  # [+name+] the name of the host
  # [+options+] additional options, such as tags and folders
  def add_host(name, folder = '', options = {})
# possible options:
#       http://localhost/watotest/check_mk/wato.py?
#    filled_in=edithost
#    &_transid=-1
#    &host=thehostname
#    &contactgroups_use=on
#    &attr_alias=
#    &attr_ipaddress=
#    &parents_0=
#    &attr_tag_agent=cmk-agent%7Ctcp
#    &attr_tag_criticality=prod
#    &attr_tag_networking=lan
#    &save=Save+%26+Finish
#    &folder=folder1
#    &mode=newhost

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

    http_request('http://localhost/watotest/check_mk/wato.py', params)
  end

  def delete_host(name, folder = '')
    # example:
    #http://localhost/watotest/check_mk/wato.py?mode=folder&_delete_host=testhost&_transid=1408580836/1995573565&folder=folder1&_do_confirm=yes 
    http_request('http://localhost/watotest/check_mk/wato.py', {
    	mode: 'folder',
	_delete_host: name,
	_transid: '-1',
	folder: folder,
	_do_confirm: 'yes',
	_do_actions: 'yes',
    })
  end

  def activate
    http_request('http://localhost/watotest/check_mk/wato_ajax_activation.py', {})
  end

  private

  def http_request(request_uri, params, debug = false)
    uri = URI.parse(request_uri)
    uri.query = URI.encode_www_form(params)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth("cmk-api", "cmk-api-secret")
    response = http.request(request)
    if debug
      puts "uri: " + uri.to_s
      pp response
      puts response.body
    end
    response.value
  end
end
