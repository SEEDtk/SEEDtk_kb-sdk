package SEEDtk::SEEDtkClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

SEEDtk::SEEDtkClient

=head1 DESCRIPTION


A KBase module: SEEDtk
This module contains various methods for accessing SEEDtk.


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => SEEDtk::SEEDtkClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my $token = Bio::KBase::AuthToken->new(@args);
	
	if (!$token->error_message)
	{
	    $self->{token} = $token->token;
	    $self->{client}->{token} = $token->token;
	}
        else
        {
	    #
	    # All methods in this module require authentication. In this case, if we
	    # don't have a token, we can't continue.
	    #
	    die "Authentication failed: " . $token->error_message;
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 missing_roles

  $return = $obj->missing_roles($workspace_name, $genome_id, $outputObject)

=over 4

=item Parameter and return types

=begin html

<pre>
$workspace_name is a SEEDtk.workspace_name
$genome_id is a SEEDtk.genome_id
$outputObject is a SEEDtk.outputObject
$return is a SEEDtk.MissingRoleData
workspace_name is a string
genome_id is a string
outputObject is a string
MissingRoleData is a reference to a hash where the following keys are defined:
	contigset_id has a value which is a SEEDtk.contigset_id
	missing_roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
	close_genomes has a value which is a reference to a list where each element is a SEEDtk.CloseGenomeItem
	found_roles has a value which is a reference to a list where each element is a SEEDtk.FoundRoleItem
contigset_id is a string
MissingRoleItem is a reference to a hash where the following keys are defined:
	role_id has a value which is a string
	role_description has a value which is a string
	genome_hits has a value which is an int
	blast_score has a value which is a float
	perc_identity has a value which is a float
	hit_location has a value which is a string
	protein_sequence has a value which is a string
	reactions has a value which is a reference to a list where each element is a SEEDtk.ReactionItem
ReactionItem is a reference to a hash where the following keys are defined:
	reaction_id has a value which is a string
	reaction_name has a value which is a string
CloseGenomeItem is a reference to a hash where the following keys are defined:
	id has a value which is a SEEDtk.genome_id
	hit_count has a value which is an int
	name has a value which is a SEEDtk.genome_name
genome_name is a string
FoundRoleItem is a reference to a hash where the following keys are defined:
	role_id has a value which is a string
	role_description has a value which is a string

</pre>

=end html

=begin text

$workspace_name is a SEEDtk.workspace_name
$genome_id is a SEEDtk.genome_id
$outputObject is a SEEDtk.outputObject
$return is a SEEDtk.MissingRoleData
workspace_name is a string
genome_id is a string
outputObject is a string
MissingRoleData is a reference to a hash where the following keys are defined:
	contigset_id has a value which is a SEEDtk.contigset_id
	missing_roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
	close_genomes has a value which is a reference to a list where each element is a SEEDtk.CloseGenomeItem
	found_roles has a value which is a reference to a list where each element is a SEEDtk.FoundRoleItem
contigset_id is a string
MissingRoleItem is a reference to a hash where the following keys are defined:
	role_id has a value which is a string
	role_description has a value which is a string
	genome_hits has a value which is an int
	blast_score has a value which is a float
	perc_identity has a value which is a float
	hit_location has a value which is a string
	protein_sequence has a value which is a string
	reactions has a value which is a reference to a list where each element is a SEEDtk.ReactionItem
ReactionItem is a reference to a hash where the following keys are defined:
	reaction_id has a value which is a string
	reaction_name has a value which is a string
CloseGenomeItem is a reference to a hash where the following keys are defined:
	id has a value which is a SEEDtk.genome_id
	hit_count has a value which is an int
	name has a value which is a SEEDtk.genome_name
genome_name is a string
FoundRoleItem is a reference to a hash where the following keys are defined:
	role_id has a value which is a string
	role_description has a value which is a string


=end text

=item Description

find missing roles in a set of contigs

=back

=cut

 sub missing_roles
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function missing_roles (received $n, expecting 3)");
    }
    {
	my($workspace_name, $genome_id, $outputObject) = @args;

	my @_bad_arguments;
        (!ref($workspace_name)) or push(@_bad_arguments, "Invalid type for argument 1 \"workspace_name\" (value was \"$workspace_name\")");
        (!ref($genome_id)) or push(@_bad_arguments, "Invalid type for argument 2 \"genome_id\" (value was \"$genome_id\")");
        (!ref($outputObject)) or push(@_bad_arguments, "Invalid type for argument 3 \"outputObject\" (value was \"$outputObject\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to missing_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'missing_roles');
	}
    }

    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
	method => "SEEDtk.missing_roles",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'missing_roles',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method missing_roles",
					    status_line => $self->{client}->status_line,
					    method_name => 'missing_roles',
				       );
    }
}
 
  

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "SEEDtk.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'missing_roles',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method missing_roles",
            status_line => $self->{client}->status_line,
            method_name => 'missing_roles',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for SEEDtk::SEEDtkClient\n";
    }
    if ($sMajor == 0) {
        warn "SEEDtk::SEEDtkClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 contigset_id

=over 4



=item Description

A string representing a ContigSet id.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 genome_id

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 genome_name

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 workspace_name

=over 4



=item Description

A string representing a workspace name.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 outputObject

=over 4



=item Description

A string representing a output object name.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ReactionItem

=over 4



=item Description

description of a role missing in the contigs


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
reaction_id has a value which is a string
reaction_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
reaction_id has a value which is a string
reaction_name has a value which is a string


=end text

=back



=head2 MissingRoleItem

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
role_id has a value which is a string
role_description has a value which is a string
genome_hits has a value which is an int
blast_score has a value which is a float
perc_identity has a value which is a float
hit_location has a value which is a string
protein_sequence has a value which is a string
reactions has a value which is a reference to a list where each element is a SEEDtk.ReactionItem

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
role_id has a value which is a string
role_description has a value which is a string
genome_hits has a value which is an int
blast_score has a value which is a float
perc_identity has a value which is a float
hit_location has a value which is a string
protein_sequence has a value which is a string
reactions has a value which is a reference to a list where each element is a SEEDtk.ReactionItem


=end text

=back



=head2 FoundRoleItem

=over 4



=item Description

description of a role found in the contigs


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
role_id has a value which is a string
role_description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
role_id has a value which is a string
role_description has a value which is a string


=end text

=back



=head2 CloseGenomeItem

=over 4



=item Description

description of a close genome


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a SEEDtk.genome_id
hit_count has a value which is an int
name has a value which is a SEEDtk.genome_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a SEEDtk.genome_id
hit_count has a value which is an int
name has a value which is a SEEDtk.genome_name


=end text

=back



=head2 MissingRoleData

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
contigset_id has a value which is a SEEDtk.contigset_id
missing_roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
close_genomes has a value which is a reference to a list where each element is a SEEDtk.CloseGenomeItem
found_roles has a value which is a reference to a list where each element is a SEEDtk.FoundRoleItem

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
contigset_id has a value which is a SEEDtk.contigset_id
missing_roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
close_genomes has a value which is a reference to a list where each element is a SEEDtk.CloseGenomeItem
found_roles has a value which is a reference to a list where each element is a SEEDtk.FoundRoleItem


=end text

=back



=cut

package SEEDtk::SEEDtkClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
