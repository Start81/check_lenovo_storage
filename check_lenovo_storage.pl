#!/usr/bin/perl -w
#=============================================================================== 
# Script Name   : check_lenovo_storage.pl
# Usage Syntax  : check_lenovo_storage.pl -H <hostname> -p <port>  -u <User> -P <password> [-t <timeout>] [-a <apiversion>] 
# Version       : 1.1.0
# Last Modified :16/05/2022
# Modified By   : Start81 (DESMAREST JULIEN)
# Description   : Nagios check for lenovo thinksystem storage hardware via API
# Depends On    : Monitoring::Plugin; Data::Dumper ;MIME::Base64; JSON; REST::Client; LWP::UserAgent
# 
# Changelog: 
#    Legend: 
#       [*] Informational, [!] Bugfix, [+] Added, [-] Removed 
#  - 13/05/2022 | 1.0.0 | [*] First release
#  - 16/05/2022 | 1.1.0 | [*] return critical on unknown status
#===============================================================================

use strict;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use warnings;
use Monitoring::Plugin;
use Data::Dumper;
use REST::Client;
use Data::Dumper;
use JSON;
use utf8; 
use MIME::Base64;
use LWP::UserAgent;
use Readonly;
use File::Basename;
my $me = basename($0);
Readonly our $VERSION => '1.1.0';
my $status = 3;
my $o_verb;
my @check_items = ("powerSupplies","controllers","batteries","drives","fans","thermalSensors");
my %state  =("optimal"=>0,
    "failed"=>2,
    "removed"=>2,
    "unknown" =>3,
    "__UNDEFINED"=>3,
    "fullCharging"=>0,
    "nearExpiration"=>1,
    "notInConfig"=>0,
    "configMismatch"=>1,
    "learning"=>0,
    "overtemp"=>2,
    "expired"=>2,
    "maintenanceCharging"=>0,
    "replacementRequired"=>2,
    "rpaParErr"=>2,
    "serviceMode"=>1,
    "suspended"=>1,
    "degraded"=>1,
    "replaced"=>0,
    "bypassed"=>1,
    "unresponsive"=>2,
    "incompatible"=>2,
    "dataRelocation"=>0,
    "preFailCopy"=>2,
    "preFailCopyPending"=>2,
    "nominalTempExceed"=>1,
    "maxTempExceed"=>2
);
sub verb { my $t=shift; if ($o_verb ) {print $t,"\n"}  ; return 0}
my $np = Monitoring::Plugin->new(
    usage => "Usage: %s -H <hostname> -p <port>  -u <User> -P <password> [-t <timeout>] [-a <apiversion>] \n",
    plugin => $me,
    shortname => 'check_lenovo_storage',
    blurb => 'Nagios check for lenovo thinksystem storage hardware via REST API',
    version => $VERSION,
    timeout => 30
);
$np->add_arg(
    spec => 'host|H=s',
    help => "-H, --host=STRING\n"
          . '   Hostname',
    required => 1
);
$np->add_arg(
    spec => 'port|p=i',
    help => "-p, --port=INTEGER\n"
          . '   Port Number',
    required => 1,
    default => "443"
);
$np->add_arg(
    spec => 'apiversion|a=s',
    help => "-a, --apiversion=string\n"
          . '   The thinksystem API version',
    required => 1,
    default => 'v2'
);
$np->add_arg(
    spec => 'user|u=s',
    help => "-u, --user=string\n"
          . '   User name for api authentication',
    required => 1,
);
$np->add_arg(
    spec => 'Password|P=s',
    help => "-P, --Password=string\n"
          . '   User password for api authentication',
    required => 1,
);

$np->add_arg(
    spec => 'ssl|S',
    help => "-S, --ssl\n"  
         . '  The thinksystem  use ssl',
    required => 0
);

$np->getopts;
my $o_host = $np->opts->host;
my $o_login = $np->opts->user;
my $o_pwd = $np->opts->Password;
my $o_apiversion = $np->opts->apiversion;
my $o_port = $np->opts->port;
my $o_use_ssl = 0;
$o_use_ssl = $np->opts->ssl if (defined $np->opts->ssl);
$o_verb = $np->opts->verbose;
my $o_timeout = $np->opts->timeout;
if ($o_timeout > 60){
    $np->plugin_die("Invalid time-out");
}
my $client = REST::Client->new();
$client->setTimeout($o_timeout);
my $url = "http://";
 
$client->addHeader('Content-Type', 'application/json;charset=utf8');
$client->addHeader('Accept', 'application/json');
$client->addHeader('Accept-Encoding',"gzip, deflate, br");
if ($o_use_ssl) {
    my $ua = LWP::UserAgent->new(
        timeout  => $o_timeout,
        ssl_opts => {
            verify_hostname => 0,
            SSL_verify_mode => SSL_VERIFY_NONE
        },
    );
    $url = "https://";
    $client->setUseragent($ua);
}
#https://10.200.136.59:8443/devmgr/v2/storage-systems/
#get storage systems list
$url = "$url$o_host:$o_port/devmgr/$o_apiversion/storage-systems/";
$client->addHeader('Authorization', 'Basic ' . encode_base64("$o_login:$o_pwd"));
verb($url);
$client->GET($url);
if($client->responseCode() ne '200'){
    print(Dumper($client));
    $np->plugin_exit('UNKNOWN', "response code : " . $client->responseCode() . " Message : Error when getting storage-systems list ". $client->{_res}->decoded_content );
}
my $rep = $client->{_res}->decoded_content;
my $storage_systems = from_json($rep);
my $i = 0;
my $j = 0;
my @criticals = ();
my @warnings = ();
my @ok = ();
my $msg;
my $hw_rep;
my $hardware;
my $hw_items;
my $id;
my %hw_inventory;
while (exists ($storage_systems->[$i])){
        $id=$storage_systems->[$i]->{'id'};
		#https://10.200.136.59:8443/devmgr/v2/storage-systems/1/hardware-inventory
        #get storage systems hardware inventory
        $url = "$url$id/hardware-inventory";
        $client->addHeader('Authorization', 'Basic ' . encode_base64("$o_login:$o_pwd"));
        verb($url);
        $client->GET($url);
        if($client->responseCode() ne '200'){
           $np->plugin_exit('UNKNOWN', "response code : " . $client->responseCode() . " Message : Error when getting storage-systems $i hardware inventory". $client->{_res}->decoded_content );
        }
        $hw_rep = $client->{_res}->decoded_content;
        $hardware = from_json($hw_rep);

        foreach my $items (@check_items){
            verb($items);
            if (exists  ($hardware->{$items})){
                $j=0;
                $hw_items = $hardware->{$items} ;
                while (exists ($hw_items->[$j])){
                    verb(" $items $j ". $hw_items->[$j]->{'status'});
                    if (exists $state{$hw_items->[$j]->{'status'}}){
                        $msg = "$items status is ". $hw_items->[$j]->{'status'} . " location : " . $hw_items->[$j]->{'physicalLocation'}->{'locationPosition'};  
                        $msg = $msg . " label " . $hw_items->[$j]->{'physicalLocation'}->{'label'} if (($hw_items->[$j]->{'physicalLocation'}->{'label'}) ne "");
                        push( @criticals, $msg) if ($state{$hw_items->[$j]->{'status'}}== 2);
                        push( @warnings, $msg) if ($state{$hw_items->[$j]->{'status'}}== 1);
                    } else {
                        push( @criticals, "$items unknown status ". $hw_items->[$j]->{'status'} ); 
                    }
                    $j=$j+1;
                }
                
                $hw_inventory{$items}=$j;
            }
        }
    $i=$i+1;
}
$np->plugin_exit('CRITICAL', join(', ', @criticals)) if (scalar @criticals > 0);
$np->plugin_exit('WARNING', join(', ', @warnings)) if (scalar @warnings > 0);
$msg="";
foreach my $items (@check_items){
    $msg = $msg . $hw_inventory{$items} . " " . $items  ." ares healthy ";
}
$np->plugin_exit('OK', $msg );
