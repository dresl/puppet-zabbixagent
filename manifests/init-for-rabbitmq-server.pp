# Class: zabbixagent-rabbitmq-server
#
# This module manages auxiliary files for the zabbix agent on a monitored machine.
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#

class zabbixagent-rabbitmq-server()
{
  #
  # variables
  #
  $file1 = "https://raw.github.com/czhujer/Zabbix-II/master/zabbix-templates/rabbitmq-server/scripts/detect_rabbitmq_nodes.sh"
  $dfile1 = "/etc/zabbix/scripts/rabbitmq/detect_rabbitmq_nodes.sh"

  $file2 = "https://raw.github.com/czhujer/Zabbix-II/master/zabbix-templates/rabbitmq-server/scripts/rabbitmq-status.sh"
  $dfile2 = "/etc/zabbix/scripts/rabbitmq/rabbitmq-status.sh"

  $file3 = "https://raw.github.com/czhujer/Zabbix-II/master/zabbix-templates/rabbitmq-server/scripts/rabbitmqadmin.py"
  $dfile3 = "/etc/zabbix/scripts/rabbitmq/rabbitmqadmin.py"

  #
  # check os and version
  #
  $os_release = $::operatingsystemrelease

  $msg_untestedrelease = "Untested version ($os_release) of operating system..."

  $msg_testedrelease = "Tested on this version ($os_release) of operating system... OK"

  $msg_untestedos = "Untested operating system..."

  if $::operatingsystem == "centosXXX" {

#    if( $os_release >= 5 and $os_release < 5.9) {
#        notice "Tested on a newer version of operating system than this ($os_release). Please update your OS."
#    }
#    elsif( $os_release >= 5 and $os_release < 6) {
#        notice $msg_testedrelease
#    }
#    elsif( $os_release >= 6 and $os_release < 6.4) {
#        notice "Tested on a newer version of operating system than this ($os_release). Please update your OS."
#    }
#    if( $os_release == 6.4) {
#        notice $msg_testedrelease
#    }
#    else {
#         notice $msg_untestedrelease
#    }
  }
  elsif($::operatingsystem == "ubuntu") {

         if( $os_release == 12.04 ){
             notice $msg_testedrelease
         }
         else {
            notice $msg_untestedrelease
         }

  }
  else{
     notice $msg_untestedos
  }

  #
  #  modify configuration files
  #

 case $::operatingsystem {

  ubuntu: {

    file { '/etc/zabbix/scripts':
        ensure  => directory,
    }

    file { '/etc/zabbix/scripts/rabbitmq':
        ensure  => directory,
	require => File["/etc/zabbix/scripts"],
    }

 $config_content = "#
#
#  discovering
#
UserParameter=rabbitmq.discovery,/etc/zabbix/scripts/rabbitmq/detect_rabbitmq_nodes.sh
UserParameter=rabbitmq.discovery_queue,/etc/zabbix/scripts/rabbitmq/detect_rabbitmq_nodes.sh queue
UserParameter=rabbitmq.discovery_exchanges,/etc/zabbix/scripts/rabbitmq/detect_rabbitmq_nodes.sh exchange
#
UserParameter=rabbitmq[*],/etc/zabbix/scripts/rabbitmq/rabbitmq-status.sh \$1 \$2 \$3 \$4
#
# counts of messages
#
UserParameter=rabbitmq.local.messages_ready.count[*],sudo rabbitmqctl -q list_queues -p \$1 messages_ready | awk '{S = S + $ 0}END{print S}'
UserParameter=rabbitmq.local.messages_unacknowledged.count[*],sudo rabbitmqctl -q list_queues -p \$1 messages_unacknowledged | awk '{S = S + $ 0}END{print S}'
UserParameter=rabbitmq.local.messages.count[*],sudo rabbitmqctl -q list_queues -p \$1 messages | awk '{S = S + $ 0}END{print S}'
"

    file { "/etc/zabbix/zabbix_agentd/zabbix-rabbitmq.conf":
        #	replace => "no", # this is the important property
	    ensure  => "present",
	    content => $config_content,
	    mode    => 644,
	    require => File['/etc/zabbix/scripts/rabbitmq'],
	    notify  => Service["zabbix-agent"],  # this sets up the relationship
    }

    exec { "download file1":
        command => "wget '$file1' -O $dfile1",
	    path => "/usr/bin",
	    require => File["/etc/zabbix/scripts/rabbitmq"],
    }

    file { "$dfile1":
	    ensure  => "present",
	    mode    => 755,
	    require => Exec["download file1"],
    }

    exec { "download file2":
        command => "wget '$file2' -O $dfile2",
	    path => "/usr/bin",
	    require => File["/etc/zabbix/scripts/rabbitmq"],
    }

    file { "$dfile2":
	    ensure  => "present",
	    mode    => 755,
	    require => Exec["download file2"],
    }

    exec { "download file3":
        command => "wget '$file3' -O $dfile3",
	    path => "/usr/bin",
	    require => Exec["download file2"],
    }

    file { "$dfile3":
	    ensure  => "present",
	    mode    => 755,
	    require => Exec["download file3"],
    }

    service {'zabbix-agent' :
        ensure  => running,
        enable  => true,
    }

    #
    # modify sudo
    #

    file { "/etc/sudoers.d/zabbix-agent-rabbitmq-support_sudoers":
        #	replace => "no", # this is the important property
	    ensure  => "present",
	    content => "#for monitoring rabbitmq-server by zabbix-agent \nzabbix  ALL=(ALL)       NOPASSWD: /usr/sbin/rabbitmqctl *\n",
	    mode    => 440,
    }

  } #case ubuntu
  default: { 
    notice "Unsupported operatingsystem  ${::operatingsystem}" 
  }

 } #case os:operationsystem

} #end of class
