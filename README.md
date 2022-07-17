# rancid-aruba
*A Perl module for Aruba devices in RANCID*

This is a proof of concept, tested on a limited number of legacy Aruba devices (namely 6000 and 7210 wireless controllers running ArubaOS 6.3 and 6.4; and S1500 and S2500 switches running ArubaOS 7.1 and 7.2.) Modern Aruba-branded switches are derived from HPE's ProVision switch line, and should be considered HP switches for the purposes of RANCID.

Install `aruba.pm` into your Perl module directory – in my Scientific Linux install it's at `/usr/share/perl5/vendor_perl/rancid/`.

There is no need for a separate login script. The included `clogin` works fine, as long as you remember to disable paging manually at login. Here is suggested content for your `/etc/rancid/rancid.types.conf` file; note I'm disabling encryption of certain passwords in the output. This may not be desirable for all.

    # ArubaOS device
    aruba;script;rancid -t aruba
    aruba;login;clogin
    aruba;module;aruba
    aruba;inloop;aruba::inloop
    aruba;command;aruba::RunCommand;no paging
    aruba;command;aruba::RunCommand;encrypt disable
    aruba;command;aruba::ShowVersion;show version
    aruba;command;aruba::ShowMasterRedundancy;show master-redundancy
    aruba;command;aruba::ShowBoot;show boot
    aruba;command;aruba::ShowImageVersion;show image version
    aruba;command;aruba::Dir;dir
    aruba;command;aruba::ShowInterfaceTransceivers;show interface transceivers
    aruba;command;aruba::ShowPacketCapture;show packet-capture
    aruba;command;aruba::ShowInventory;show inventory
    aruba;command;aruba::ShowVLAN;show vlan
    aruba;command;aruba::WriteTerm;write term
