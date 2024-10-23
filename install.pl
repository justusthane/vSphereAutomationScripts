#!/bin/perl
use File::Copy;
use feature 'signatures';
use POSIX;
die "Error: must pass username as argument" if (! $ARGV[0]);

open(my $fh_log, ">>", "install.log");

$script_dest = '/usr/local/bin/vsphereAutomation';
$systemd_dest = '/etc/systemd/system';
$snapshotReport_systemd_override = "$systemd_dest/vsphereSnapshotReport.service.d";
$DRSGroupMgmt_systemd_override = "$systemd_dest/vsphereDRSGroupMgmt.service.d";
$credentialServer_systemd_override = "$systemd_dest/vsphereAutomationCredentialServer.service.d";

sub get_date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = $year + 1900;
	$mon++;
	return "$year/$mon/$mday $hour:$min";
}

sub log_line {
	print $fh_log strftime "%Y-%m-%d %H:%M:%S ", localtime time;
	print $fh_log "$_[0]\n";
}


sub install_files {
	my (%args) = @_;

	my $dir = $args{dir};
	my $dest = $args{dest};
	my $chmod = $args{chmod} || 0;

	chdir $dir;
	while (my $file = glob ('*')) {
		log_line("Copying $file");
		copy $file, "$dest/$file";
		chmod 0755, "$dest/$file" if $chmod;
	}
	chdir "..";
}


if (! -d $script_dest) {
	log_line("Creating directory $script_dest");
	mkdir $script_dest;
}
if (! -d $snapshotReport_systemd_override) {
	log_line("Creating directory $snapshotReport_systemd_override");
	mkdir $snapshotReport_systemd_override;
}
if (! -d $DRSGroupMgmt_systemd_override) {
	log_line("Creating directory $DRSGroupMgmt_systemd_override");
	mkdir $DRSGroupMgmt_systemd_override;
}

install_files(dir => "scripts", dest => $script_dest, chmod => "true");
install_files(dir => "systemd", dest => $systemd_dest);


open(my $fh_snapshotReport_systemd_override, ">", "$snapshotReport_systemd_override/override.conf");
print $fh_snapshotReport_systemd_override <<"EOF";
[Service]
Environment=\"USERNAME=$ARGV[0]\"
EOF
undef $fh_snapshotReport_systemd_override;
open(my $fh_DRSGroupMgmt_systemd_override, ">", "$DRSGroupMgmt_systemd_override/override.conf");
print $fh_DRSGroupMgmt_systemd_override <<"EOF";
[Service]
Environment=\"USERNAME=$ARGV[0]\"
EOF
undef $fh_DRSGroupMgmt_systemd_override;
open(my $fh_credentialServer_systemd_override, ">", "$credentialServer_systemd_override/override.conf");
print $fh_credentialServer_systemd_override <<"EOF";
[Service]
Environment=\"USERNAME=$ARGV[0]\"
EOF
undef $fh_credentialServer_systemd_override;
system("systemctl daemon-reload");
system("systemctl enable vsphereAutomationCredentialServer.service");
system("systemctl start vsphereAutomationCredentialServer.service");
system("systemctl enable vsphereSnapshotReport.timer");
system("systemctl start vsphereSnapshotReport.timer");
system("systemctl enable vsphereDRSGroupMgmt.timer");
system("systemctl start vsphereDRSGroupMgmt.timer");
undef $fh_log;
