#!/bin/perl
use File::Copy;
use feature 'signatures';
use POSIX;
die "Error: must pass username as argument" if (! $ARGV[0]);

open(my $fh_log, ">>", "install.log");

$script_dest = '/usr/local/bin/vsphereAutomation';
$systemd_dest = '/etc/systemd/system';
$systemd_override_dir = "$systemd_dest/vsphereSnapshotReport.service.d";

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
if (! -d $systemd_override_dir) {
	log_line("Creating directory $systemd_override_dir");
	mkdir $systemd_override_dir;
}

install_files(dir => "scripts", dest => $script_dest, chmod => "true");
install_files(dir => "systemd", dest => $systemd_dest);


open(my $fh_systemd_override, ">", "$systemd_override_dir/override.conf");
print $fh_systemd_override <<"EOF";
[Service]
Environment=\"USERNAME=$ARGV[0]\"
EOF
system("systemctl daemon-reload");
system("systemctl enable vsphereAutomationCredentialServer.service");
system("systemctl start vsphereAutomationCredentialServer.service");
system("systemctl enable vsphereSnapshotReport.timer");
system("systemctl start vsphereSnapshotReport.timer");
system("systemctl enable vsphereDRSGroupMgmt.timer");
system("systemctl start vsphereDRSGroupMgmt.timer");
undef $fh_systemd_override;
undef $fh_log;
