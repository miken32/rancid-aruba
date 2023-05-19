package aruba;
##
## rancid 3.1
## Copyright (c) 1997-2014 by Terrapin Communications, Inc.
## All rights reserved.
##
## This code is derived from software contributed to and maintained by
## Terrapin Communications, Inc. by Henry Kilmer, John Heasley, Andrew Partan,
## Pete Whiting, Austin Schutz, and Andrew Fort.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
## 3. All advertising materials mentioning features or use of this software
##    must display the following acknowledgement:
##        This product includes software developed by Terrapin Communications,
##        Inc. and its contributors for RANCID.
## 4. Neither the name of Terrapin Communications, Inc. nor the names of its
##    contributors may be used to endorse or promote products derived from
##    this software without specific prior written permission.
## 5. It is requested that non-binding fixes and modifications be contributed
##    back to Terrapin Communications, Inc.
##
## THIS SOFTWARE IS PROVIDED BY Terrapin Communications, INC. AND CONTRIBUTORS
## ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
## TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
## PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COMPANY OR CONTRIBUTORS
## BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
#
#  RANCID - Really Awesome New Cisco confIg Differ
#
#  aruba.pm - ArubaOS rancid procedures

use 5.005;
use strict 'vars';
use warnings;
no warnings 'uninitialized';
require(Exporter);
our @ISA = qw(Exporter);

use rancid;
use Sort::Naturally;

@ISA = qw(Exporter rancid main);

# load-time initialization
sub import {
	0;
}

# post-open(collection file) initialization
sub init {
	# add content lines and separators
	ProcessHistory("","","","!RANCID-CONTENT-TYPE: $devtype\n!\n");
	ProcessHistory("COMMENTS","keysort","A0","!\n");
	ProcessHistory("COMMENTS","keysort","B0","!\n");
	ProcessHistory("COMMENTS","keysort","C0","!\n");
	ProcessHistory("COMMENTS","keysort","D0","!\n");
	ProcessHistory("COMMENTS","keysort","E0","!\n");
	ProcessHistory("COMMENTS","keysort","F0","!\n");
	ProcessHistory("COMMENTS","keysort","G0","!\n");
	ProcessHistory("COMMENTS","keysort","H0","!\n");
	ProcessHistory("COMMENTS","keysort","I0","!\n");
	0;
}

# main loop of input of device output
sub inloop {
	my($INPUT, $OUTPUT) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	my($cmd, $rval);

TOP:
	while(<$INPUT>) {
		tr/\015//d;
		if (/[>#]\s?exit/) {
			$clean_run = 1;
			last;
		}
		if (/^Error:/) {
			print STDOUT ("$host clogin error: $_");
			print STDERR ("$host clogin error: $_") if ($debug);
			$clean_run = 0;
			last;
		}
		while (/[>#]\s*($cmds_regexp)\s*$/) {
			$cmd = $1;
			if (!defined($prompt)) {
				$prompt = ($_ =~ /^([^#>]+[#>])/)[0];
				$prompt =~ s/([][}{)(\\*])/\\$1/g;
				print STDERR ("PROMPT MATCH: $prompt\n") if ($debug);
			}
			print STDERR ("HIT COMMAND:$_") if ($debug);
			if (! defined($commands{$cmd})) {
				print STDERR "$host: found unexpected command - \"$cmd\"\n";
				$clean_run = 0;
				last TOP;
			}
			$rval = &{$commands{$cmd}}($INPUT, $OUTPUT, $cmd);
			delete($commands{$cmd});
			if ($rval == -1) {
				$clean_run = 0;
				last TOP;
			}
		}
	}
}

# This routine parses "show version"
sub ShowVersion {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		/^ArubaOS \(MODEL: ([A-Za-z0-9_-]*)\), .*Version\s+(.*)$/ &&
			ProcessHistory("COMMENTS","keysort","A1","!Model: $1\n") &&
			ProcessHistory("COMMENTS","keysort","D1","!Image: Software: $2\n") && next;

		/^Compiled (.*)$/ &&
	    	ProcessHistory("COMMENTS","keysort","D2","!Image: Compiled: $1\n") && next;

		/^ROM: (System )?Bootstrap.*(Version.*)$/ &&
			ProcessHistory("COMMENTS","keysort","C1","!ROM Bootstrap: $2\n") && next;

		/^Processor (.+) with (\d+) bytes/ &&
			ProcessHistory("COMMENTS","keysort","A2","!CPU: $1\n") &&
			ProcessHistory("COMMENTS","keysort","B1","!Memory: $2 bytes\n") && next;

		/^(\d+[gmk]) bytes of (.* flash)/i &&
	    	ProcessHistory("COMMENTS","keysort","B2", "!Memory: $2 $1 bytes\n") && next;
	}
	return(0);
}

# This routine parses "show master-redundancy"
sub ShowMasterRedundancy {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		/^Master switch redundancy is not configured$/ &&
			ProcessHistory("COMMENTS","keysort","E1","!Redundancy: Not configured\n") && return(0);

		/^\s+?VRRP Id (\d+) current state is (.*)$/ &&
			ProcessHistory("COMMENTS","keysort","E1","!Redundancy: Role is $2\n") && 
		    ProcessHistory("COMMENTS","keysort","E2","!Redundancy: VRRP ID $1\n") && next;

		/^\s+?Peer's IP Address is (.+)$/ &&
			ProcessHistory("COMMENTS","keysort","E4","!Redundancy: Peer IP $1\n") && next;

		/^\s+?Peer's IPSEC Key is (.+)$/ &&
			$filter_pwds >= 1 &&
			ProcessHistory("COMMENTS","keysort","E3","!Redundancy: IPSEC key $1\n") && next;
	}
	return(0);
}

# This routine parses "show interface transceivers"
sub ShowInterfaceTransceivers {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	my($int, $mfg, $sn, $pn, $typ);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		next if (/^-+$/);
		next if (/^Transceiver information not present$/);

		/^([A-Z0-9\/]+)$/ && 
			($int && ProcessHistory("COMMENTS","keysort","F1","!Transceiver: $int: $mfg $pn (serial $sn) $typ\n")) &&
			($int = $1) && next;
		/^Vendor Name\s+:\s+(.*)$/ &&
			($mfg = $1) && next;
		/^Vendor Serial Number\s+:\s+(.*)$/ && 
			($sn = $1) && next;
		/^Vendor Part Number\s+:\s+(.*)$/ &&
			($pn = $1) && next;
		/^Cable Type\s+:\s+(.*)$/ &&
			($typ = $1) && next;
		/^Connector Type\s+:\s+(.*)$/ &&
			($typ .= " $1") && next;
	}
	return(0);
}

# This routine parses "show boot"
sub ShowBoot {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	my ($file, $part) = "";

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		/^Config File: (.*)$/ &&
			($file=$1) && next;
		/^Boot Partition: PARTITION (\d+)$/ &&
			($part=$1) && next;
    }
	ProcessHistory("COMMENTS","keysort","D3","!Boot: Partition$part:$file\n");
	return(0);
}


# This routine parses "show image version"
sub ShowImageVersion {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);
		ProcessHistory("COMMENTS","keysort","D99","!$_");
	}
	return(0);
}

# This routine parses "show whitelist"
sub ShowWhitelist {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);
		ProcessHistory("COMMENTS","keysort","G1","!$_");
	}
	return(0);
}

# This routine parses "show crashfino"
sub ShowCrashinfo {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);
		ProcessHistory("COMMENTS","keysort","G1","!$_");
	}
	return(0);
}

# This routine parses "dir"
sub Dir {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		/^[-d](?:[-r][-w][-x]){3}\s+\d+\s+\S+\s+\S+\s+(\d+)\s+[A-Za-z]{3}\s+\d+\s+[\d:]+\s+(.*)$/ &&
			ProcessHistory("FLASH","","","!Flash: $2\n");
	}
	ProcessHistory("FLASH","","","!\n");
	return(0);
}


# This routine parses "show inventory".
sub ShowInventory {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		/^SC Model(?: Name|#)\s+:\s+(.*)$/ &&
			ProcessHistory("INVENTORY","keysort","A0", "!Inventory: Model: $1\n") && next;

		/^((.*) (Serial|Assembly|Revision) ?#?)\s+:\s+(.*)$/ &&
			ProcessHistory("INVENTORY","keysort","A0$2", "!Inventory: $1: $4\n") && next;
	}
	ProcessHistory("INVENTORY","","","!\n");
	return(0);
}


# This routine parses "show packet-capture"
sub ShowPacketCapture {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	my $capture_type = "";
	my $capture_found = 0;

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		next if (/^-+$/);

		/^Active Capture Destination$/ &&
			($capture_type = "") && next;
		/^Active Capture (Controlpath)$/ &&
			($capture_type = "Controlpath") && next;
		/^Active Capture (Datapath)$/ &&
			($capture_type = "Datapath") && next;
		/^(.*)\s+Enabled\s+(.*)$/ &&
			ProcessHistory("CAPTURE","","","!Capture: $capture_type $1: $2\n") && next;
        	$capture_found = 1
	}
	($capture_found) && ProcessHistory("CAPTURE","","","!\n");
	return(0);
}

# Utility routine for turning "GE0/0/1-2 GE0/0/0" into "GE0/0/0 GE0/0/1 GE0/0/2"
sub ParseVLANPorts {
	my (@portlist) = @_;
	my @newportlist = ();
	my ($portspec, $base, $start, $end) = "";
	my $i = 0;
	foreach $portspec (@portlist) {
		if ($portspec =~ /(.*?\/?)(\d+)-(\d+)$/) {
			$base = $1;
			$start = $2;
			$end = $3;
			for ($i = $start; $i <= $end; $i++) {
				push(@newportlist, "$base$i");
			}
		} else {
			push(@newportlist, $portspec);
		}   
	}
	return nsort @newportlist;
}

# This routine parses "show vlan"
sub ShowVLAN {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	my ($vlan, $vlan_name, $ports, $aaa_profile, $temp) = "";
	my @vlan_ports;
	my ($len, $has_aaa) = 0;

	while (<$INPUT>) {
		tr/\015//d;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		/AAA Profile$/ && ($has_aaa = 1);
		/^VLAN CONFIG/ && next;
		/^-+/ && next;

		if (/^(VLAN  )(Description +)(Ports)/) {
			#figure out width of the "Description" column; assume at least one space after
			$len = length($2) - 1;
		}
		if (/^(\d+)\s+(.{${len}})\s(.*)$/) {
			#beginning of a VLAN definition
			if ($vlan) {
				#write the previous one
				@vlan_ports = ParseVLANPorts(@vlan_ports);
				ProcessHistory("COMMENTS","keysort","I$vlan","!VLAN $vlan ($vlan_name): @vlan_ports\n");
			}
			#get details for the new one
			$vlan = $1;
			$vlan_name = $2;
			$temp = $3;
			#trimming values
			$vlan =~ s/^\s+|\s+$//g;
			$vlan_name =~ s/^\s+|\s+$//g;
			$temp =~ s/^\s+|\s+$//g;
			if ($has_aaa) {
				($ports, $aaa_profile) = split(/\s{2,}/, $temp);
			} else {
				$ports = $temp;
			}
			@vlan_ports=split(/ /, $ports);
			next;
		}

		if (/^\s+(.*)$/) {
			#continuing VLAN definition
			$temp = $1;
			$temp =~ s/^\s+|\s+$//g;
			if ($has_aaa) {
				($ports, $aaa_profile) = split(/\s{2,}/, $temp);
			} else {
				$ports = $temp;
			}
			#adding to existing array
			@vlan_ports = (@vlan_ports, split(/ /, $ports));
			next;
		}
		
	}   
	ProcessHistory("COMMENTS","","","!\n");
	return(0);
}

# This routine processes a "write term"
sub WriteTerm {
	my($INPUT, $OUTPUT, $cmd) = @_;
	my $sub_name = (caller(0))[3];
	print STDERR "    In $sub_name: $_" if ($debug);

	my($lineauto, $comment, $linecnt) = (0,0,0);

	while (<$INPUT>) {
		tr/\015//d;
		# strip trailing spaces
		s/ +$//;
		last if (/^$prompt/);
		return(1) if (/^\s*($cmd|\^)\s*$/);
		return(1) if (/invalid input detected/i);
		return(1) if (/do not have permission/i);

		return(0) if ($found_end);

		# skip emtpy lines at the beginning
		if (!$linecnt && /^\s*$/) {
			next;
		}

		$linecnt++;
		$lineauto = 0 if (/^[^ ]/);
		# skip the crap
		if (/^(##+|(building|current) configuration)/i) {
		    while (<$INPUT>) {
				next if (/^Current configuration\s*:/i);
				next if (/^:/);
				next if (/^([%!#].*|\s*)$/);
				last;
		    }
		    tr/\015//d;
		}

		# skip consecutive comment lines to avoid oscillating extra comment
		# line on some access servers.  grrr.
		if (/^!\s*$/) {
			next if ($comment);
			ProcessHistory("","","",$_);
			$comment++;
			next;
		}
		$comment = 0;

		if ($filter_pwds >= 2) {
			#removing any passwords
			/^(enable secret )/ &&
				ProcessHistory("ENABLE","","","!$1<removed>\n") && next;

			/^mgmt-user (\S+) (\S+) (.*)$/ &&
				ProcessHistory("USER","keysort","$1","!mgmt-user $1 $2 <removed>\n") && next;
		}

		if ($filter_pwds >= 2 || $filter_osc >= 1) {
			#within aaa-server details
			/^(\s*key )[0-9a-f]{16,}/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;
		}

		if ($filter_pwds >= 1 || $filter_osc >= 1) {
			#removing only reversible passwords
			/^(\s*wpa-passphrase )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#not editable, but we'll treat it like a password
			/^(\s*arm-rf-domain-key )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#within redundancy-master settings
			/^(\s*peer-ip-address \S+ ipsec )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#within vrrp
			/^(\s*authentication )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;
			/^(\s*vrrp-id \d+ vrrp-passphrase )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#AP console passwords
			/^(\s*ap-console-password )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;
			/^(\s*bkup-passwords )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#stored in plain text!
			/^(ntp authentication-key \S+ md5 )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#auth password only
			/^(snmp-server user \S+ auth-prot \S+ )\S+$/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#priv password also
			/^(snmp-server user \S+ auth-prot \S+ )\S+( priv-prot \S+ )\S+$/ &&
				ProcessHistory("","","","!$1<removed>$2<removed>\n") && next;

			/^(ap mesh-recovery-profile cluster \S+ wpa-hexkey )/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			#clearpass radius
			/^(\s*cppm username \S+ password )\S+/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			# upgrade-profile
			/^(\s*password )\S+/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			# dump-collection-profile
			/^(\s*server-password )\S+/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;

			# ifmap cppm
			/^(\s*server host \S+ port \S+ username \S+ passwd )\S+/ &&
				ProcessHistory("","","","!$1<removed>\n") && next;
		}

		#removing no passwords but still treating differently
		/^(enable secret )/ &&
			ProcessHistory("ENABLE","","","$_") && next;
		/^mgmt-user (\S+) (\S+) (.*)$/ &&
			ProcessHistory("USER","keysort","$1","$_") && next;

		# order and prune snmp-server host statements
		if ($filter_commstr) {
			/^(snmp-server community )/ &&
				ProcessHistory("","","","$1 <removed>\n") && next;

			/^(snmp-server host (\d+\.\d+\.\d+\.\d+) version [1-3]c? )\S+(.*)?$/ &&
				ProcessHistory("SNMPSERVERHOST","ipsort","$2","!$1<removed>$2\n") && next;
		} else {
			/^snmp-server host (\d+\.\d+\.\d+\.\d+)/ &&
				ProcessHistory("SNMPSERVERHOST","ipsort","$1","$_") && next;
		}

		# order ntp servers
		/^ntp server (\d+\.\d+\.\d+\.\d+)/ &&
			ProcessHistory("NTP","ipsort",$1,"$_") && next;

		# catch anything that wasnt matched above.
		ProcessHistory("","","","$_");

		# end of config.
		if (/^end$/) {
			$found_end = 1;
			return(0);
		}
	}

	return(0);
}

1;
