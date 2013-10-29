# Class: zabbixagent-linux-disk-io-stats
#
# This module manages auxiliary files and configurations for the zabbix agent on a monitored machine.
#
# Parameters: none
#
# Actions:
#
# Requires: no Requires
#

class zabbixagent-linux-disk-io-stats()
{
  #
  # variables
  #
  $file1 = "https://raw.github.com/czhujer/Zabbix-II/master/zabbix-templates/linux-disk-io-stats/usr-local-bin/discover_disk.pl"
  $dfile1 = "/usr/local/bin/discover_disk.pl"

  $file2 = "https://raw.github.com/czhujer/Zabbix-II/master/zabbix-templates/linux-disk-io-stats/usr-local-bin/zbx_parse_iostat_values.sh"
  $dfile2 = "/usr/local/bin/zbx_parse_iostat_values.sh"

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

    file { '/etc/zabbix/zabbix_agentd':
        ensure  => directory,
    }

 $config_content = "#
#
# diskio discovery
#
UserParameter=custom.disks.iostats.discovery_perl,/usr/local/bin/discover_disk.pl
#
# io stats values
#
UserParameter=custom.vfs.dev.iostats.rrqm[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$2}'
UserParameter=custom.vfs.dev.iostats.wrqm[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$3}'
UserParameter=custom.vfs.dev.iostats.rps[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$4}'
UserParameter=custom.vfs.dev.iostats.wps[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$5}'
UserParameter=custom.vfs.dev.iostats.rsec[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$6}'
UserParameter=custom.vfs.dev.iostats.wsec[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$7}'
UserParameter=custom.vfs.dev.iostats.avgrq[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$8}'
UserParameter=custom.vfs.dev.iostats.avgqu[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$9}'
UserParameter=custom.vfs.dev.iostats.await[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$10}'
UserParameter=custom.vfs.dev.iostats.svctm[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$11}'
UserParameter=custom.vfs.dev.iostats.util[*],/usr/local/bin/zbx_parse_iostat_values.sh \$1 | awk '{print \$\$12}'
"

    file { "/etc/zabbix/zabbix_agentd/zabbix-disk-io-stats.conf":
        #       replace => "no", # this is the important property
            ensure  => "present",
            content => $config_content,
            mode    => 644,
            require => File['/etc/zabbix/zabbix_agentd'],
            notify  => Service["zabbix-agent"],  # this sets up the relationship
    }

    exec { "download file1":
        command => "wget '$file1' -O $dfile1",
            path => "/usr/bin",
            require => File["/etc/zabbix/zabbix_agentd/zabbix-disk-io-stats.conf"],
    }

    file { "$dfile1":
            ensure  => "present",
            mode    => 755,
            require => Exec["download file1"],
    }

    exec { "download file2":
            command => "wget '$file2' -O $dfile2",
            path => "/usr/bin",
    }

    file { "$dfile2":
            ensure  => "present",
            mode    => 755,
            require => Exec["download file2"],
    }

    service {'zabbix-agent' :
        ensure  => running,
        enable  => true,
    }


  } #case ubuntu
  default: {
    notice "Unsupported operatingsystem  ${::operatingsystem}"
  }

 } #case os:operationsystem

} #end of class

#class { 'zabbixagent-linux-disk-io-stats' : }

