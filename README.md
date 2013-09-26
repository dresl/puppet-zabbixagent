# Zabbix Agent Puppet Module
This module manages the zabbix agent for a monitored machine.

This module has been originally tested against Puppet 3.0.1 on Windows Server 2008R2, Ubuntu Server 12.04, and CentOS 6.3.

### requirements

cprice404/inifile ::: puppet module install cprice404/inifile
puppetlabs/stdlib ::: puppet module install puppetlabs/stdlib


### Authors
* Scott Smerchek <scott.smerchek@softekinc.com>

### Contributors

* Patrik Majer (@czhujer) <patrik.majer.pisek@gmail.com>    
    
## Usage

```puppet
class { 'zabbixagent':
  servers  => 'zabbix.example.com', # Optional: defaults to localhost (accepts an array)
  active_servers  => 'zabbix.example.com', # Optional: defaults to localhost (accepts an array)
  hostname => 'web01.example.com', # Optional: defaults to the hostname of the machine
  version => '2' #choose version of zabbix-agent: 1 or 2
}
```

This is the only configuration supported at this time. Custom user parameters may
come at a later date. If there is any other configuration that ought to be made available,
then please let me know.