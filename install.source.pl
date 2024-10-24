#!/bin/perl
# Load modules from within project directory
use lib qw(modules/share/perl5/5.32); 
use File::Copy;
use feature 'signatures';
use POSIX;
use Config::Tiny;

my $config = Config::Tiny->read('CONFIG.ini');
open(my $fh_log, ">>", "install.log");

$script_dest = '/usr/local/bin/vsphereAutomation';
$systemd_dest = '/etc/systemd/system';

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

sub create_systemd_override {
  my $service_name = $_[0];
  my $override_dir = "${systemd_dest}/${service_name}.service.d";
  my $config_vsphere_user = $config->{_}->{vsphere_user};
  my $config_vsphere_address = $config->{_}->{vsphere_address};
  my $config_smtp_server = $config->{_}->{smtp_server};
  my $config_email_from = $config->{_}->{email_from};
  my $config_email_to = $config->{_}->{email_to};

  if (! -d "$override_dir") {
    log_line("Creating directory $override_dir");
    mkdir "$override_dir";
  }
  open(my $fh, ">", "$override_dir/override.conf");
  print $fh <<"EOF";
[Service]
Environment=\"VSPHERE_USERNAME=$config_vsphere_user\"
Environment=\"VSPHERE_ADDRESS=$config_vsphere_address\"
Environment=\"SMTP_SERVER=$config_smtp_server\"
Environment=\"EMAIL_FROM=$config_email_from\"
Environment=\"EMAIL_TO=$config_email_to\"
EOF
  undef $fh;
}

if (! -d $script_dest) {
	log_line("Creating directory $script_dest");
	mkdir $script_dest;
}

install_files(dir => "scripts", dest => $script_dest, chmod => "true");
install_files(dir => "systemd", dest => $systemd_dest);
create_systemd_override("vsphereAutomationCredentialServer");
create_systemd_override("vsphereDRSGroupMgmt");
create_systemd_override("vsphereSnapshotReport");
system("systemctl daemon-reload");
system("systemctl enable vsphereAutomationCredentialServer.service");
system("systemctl start vsphereAutomationCredentialServer.service");
system("systemctl enable vsphereSnapshotReport.timer");
system("systemctl start vsphereSnapshotReport.timer");
system("systemctl enable vsphereDRSGroupMgmt.timer");
system("systemctl start vsphereDRSGroupMgmt.timer");
undef $fh_log;
