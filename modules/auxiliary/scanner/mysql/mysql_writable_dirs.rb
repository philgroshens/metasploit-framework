##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Auxiliary

  include Msf::Exploit::Remote::MYSQL
  include Msf::Auxiliary::Report
  include Msf::Auxiliary::Scanner

  def initialize
    super(
      'Name'           => 'MYSQL Directory Write Test',
      'Description'    => %Q{
          Enumerate writeable directories using the MySQL SELECT INTO DUMPFILE feature, for more
        information see the URL in the references.
      },
      'Author'         => [ 'AverageSecurityGuy <stephen[at]averagesecurityguy.info>' ],
      'References'  => [
        [ 'URL', 'https://dev.mysql.com/doc/refman/5.7/en/select-into.html' ]
      ],
      'License'        => MSF_LICENSE
    )

    register_options([
      OptPath.new('DIR_LIST', [ true, "List of directories to test", '' ]),
      OptString.new('FILE_NAME', [ true, "Name of file to write", Rex::Text.rand_text_alpha(8) ]),
      OptString.new('TABLE_NAME', [ true, "Name of table to use - Warning, if the table already exists its contents will be corrupted", Rex::Text.rand_text_alpha(8) ]),
      OptString.new('USERNAME', [ true, 'The username to authenticate as', "root" ])
    ])

  end

  # This function does not handle any errors, if you use this
  # make sure you handle the errors yourself
  def mysql_query_no_handle(sql)
    res = @mysql_handle.query(sql)
    res
  end

  def run_host(ip)
    vprint_status("Login...")

    if (not mysql_login_datastore)
      return
    end

    file = File.new(datastore['DIR_LIST'], "r")
    file.each_line do |line|
      check_dir(line.chomp)
    end
    file.close

  end

  def check_dir(dir)
    begin
      vprint_status("Checking #{dir}...")
      res = mysql_query_no_handle("SELECT _utf8'test' INTO DUMPFILE '#{dir}/" + datastore['FILE_NAME'] + "'")
    rescue ::RbMysql::ServerError => e
      vprint_warning("#{e.to_s}")
      return
    rescue Rex::ConnectionTimeout => e
      vprint_error("Timeout: #{e.message}")
      return
    else
      print_good("#{dir} is writeable")
      report_note(
        :host  => rhost,
        :type  => "filesystem.file",
        :data  => "#{dir} is writeable",
        :port  => rport,
        :proto => 'tcp',
        :update => :unique_data
      )
    end

    return
  end

end