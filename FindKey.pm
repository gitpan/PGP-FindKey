package PGP::FindKey; 

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;

sub new {
	my ($this, @args) = @_;
	my $class = shift; 
	my $self = bless { @_ }, $class;
	return $self->_init(@_);
}


sub _init {
	my($self, %params) = @_;;

	# Caller can set:
	#  \- address:		(mandatory)
	#  \- keyserver: 	(default to 'keyserver.pgp.com')
	#  \- path:		(default to '/pks/lookup')
	#  \- command:		(default to '?op=index&search=')
    
	return undef unless exists($params{address});
	$self->{keyserver} 	||= 'keyserver.pgp.com';
	$self->{path} 		||= '/pks/lookup';
	$self->{command}	||= '?op=index&search=';
	$self->{address}	||= uri_escape($params{address});

	my $query = "http://" . $self->{keyserver} . $self->{path} . $self->{command} . $self->{address};

	my $ua = LWP::UserAgent->new();
	
	# Check for *_proxy env vars.  Use them if they're there.
	$ua->env_proxy();
	
	# Get the page.

	my $req = new HTTP::Request('GET' => $query); 
	my $res = $ua->request($req);
	unless($res->is_success){ 
		warn(__PACKAGE__ . ":" . $res->status_line);
		return undef;
	}
	my $page = $res->content;
	
	# Parse the response page.  $count contains number of re matches. 
	#                           type / size / keyid
	my $count =()= $page =~ m!pub  \d{4}/<a.*?href.*?>(.{8})!g;

	# We must only have one key match.  This is explained POD-wards.
	return undef unless $count == 1;
	$self->{_result} = $1;
	return $self;
}

sub result { return $_[0]->{_result} }

1;
__END__

=head1 NAME

PGP::FindKey - Perl interface to finding PGP keyids from e-mail addresses.

=head1 SYNOPSIS

  use PGP::FindKey; 
  $obj = new PGP::FindKey
  	( 'keyserver' 	=> 'keyserver.pgp.com', 
	  'address' 	=> 'remote_user@their.address' );
  die( "The key could not be found, or there was one than one match.\n" ) unless defined($obj);

  print $obj->result;	# the keyid for $obj->address. 

=head1 DESCRIPTION

Perl interface to finding PGP keyids from e-mail addresses.

=head1 METHODS

=over 4

=item new

Creates a new PGP::FindKey object.  Parameters:

address:	(mandatory)	E-mail address to be translated.
keyserver:	(optional)	Default to 'keyserver.pgp.com'.
path:		(optional)	Default to '/pks/lookup?'.
command:	(optional)	Default to '?op=index&search='.

=back

=head1 NOTES

The module will return undef if more than one key is present for an address.  Quite simply, this is because not verifying the authenticity of the public key in this case would be foolish. 

=head1 TODO

Plenty of things:
  \-  More information about the key found.
  \-  More meaningful error reporting.
  \-  Other mechanisms.  $want_array param, more OO.

=head1 AUTHOR

Chris Ball <chris@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
