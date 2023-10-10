## check_lenovo_storage

check Hardware for lenovo thinksystem storage via REST API

### prerequisites

This script uses theses libs : 
REST::Client, Data::Dumper, Monitoring::Plugin, MIME::Base64, JSON, LWP::UserAgent, Readonly

to install them type :

```
sudo cpan REST::Client Data::Dumper Monitoring::Plugin MIME::Base64 JSON LWP::UserAgent Readonly
```

### Use case

```bash
check_lenovo_storage.pl 1.1.0

This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
It may be used, redistributed and/or modified under the terms of the GNU
General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).

Nagios check for lenovo thinksystem storage hardware via REST API

Usage: check_lenovo_storage.pl -H <hostname> -p <port>  -u <User> -P <password> [-t <timeout>] [-a <apiversion>]

 -?, --usage
   Print usage information
 -h, --help
   Print detailed help screen
 -V, --version
   Print version information
 --extra-opts=[section][@file]
   Read options from an ini file. See https://www.monitoring-plugins.org/doc/extra-opts.html
   for usage and examples.
 -H, --host=STRING
   Hostname
 -p, --port=INTEGER
   Port Number
 -a, --apiversion=string
   The thinksystem API version
 -u, --user=string
   User name for api authentication
 -P, --Password=string
   User password for api authentication
 -S, --ssl
  The thinksystem  use ssl
 -t, --timeout=INTEGER
   Seconds before plugin times out (default: 30)
 -v, --verbose
   Show details for command-line debugging (can repeat up to 3 times)
```

Exemples de commande à  exécuter à  partir du poller Nagios/Shinken/centreon :

```bash
check_lenovo_storage.pl -H <IP> -S -p 443 -u monitor -P "password"
```
you may get :
```bash
check_lenovo_storage OK - 2 powerSupplies ares healthy 2 controllers ares healthy 2 batteries ares healthy 10 drives ares healthy 4 fans ares healthy 6 thermalSensors ares healthy
```

