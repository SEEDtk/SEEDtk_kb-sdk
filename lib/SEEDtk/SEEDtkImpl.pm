package SEEDtk::SEEDtkImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

SEEDtk

=head1 DESCRIPTION

A KBase module: SEEDtk
This module contains various methods for accessing SEEDtk.

=cut

#BEGIN_HEADER
use Bio::KBase::AuthToken;
use Bio::KBase::workspace::Client;
use Config::IniFiles;
use Data::Dumper;
use FIG_Config;
use STKServices;
use MissingRoles;
use File::Copy::Recursive;
no warnings qw(once);
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my $config_file = $ENV{ KB_DEPLOYMENT_CONFIG };
    my $cfg = Config::IniFiles->new(-file=>$config_file);
    my $wsInstance = $cfg->val('SEEDtk','workspace-url');
    die "no workspace-url defined" unless $wsInstance;

    $self->{'workspace-url'} = $wsInstance;

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
        $self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 missing_roles

  $return = $obj->missing_roles($workspace_name, $contigset_id, $genome_id, $genome_name)

=over 4

=item Parameter and return types

=begin html

<pre>
$workspace_name is a SEEDtk.workspace_name
$contigset_id is a SEEDtk.contigset_id
$genome_id is a SEEDtk.genome_id
$genome_name is a SEEDtk.genome_name
$return is a SEEDtk.MissingRoleData
workspace_name is a string
contigset_id is a string
genome_id is a string
genome_name is a string
MissingRoleData is a reference to a hash where the following keys are defined:
        roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
        contigset_id has a value which is a SEEDtk.contigset_id
MissingRoleItem is a reference to a hash where the following keys are defined:
        role_id has a value which is a string
        role_description has a value which is a string
        genome_hits has a value which is an int
        blast_score has a value which is a float
        perc_identity has a value which is a float
        hit_location has a value which is a string

</pre>

=end html

=begin text

$workspace_name is a SEEDtk.workspace_name
$contigset_id is a SEEDtk.contigset_id
$genome_id is a SEEDtk.genome_id
$genome_name is a SEEDtk.genome_name
$return is a SEEDtk.MissingRoleData
workspace_name is a string
contigset_id is a string
genome_id is a string
genome_name is a string
MissingRoleData is a reference to a hash where the following keys are defined:
        roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
        contigset_id has a value which is a SEEDtk.contigset_id
MissingRoleItem is a reference to a hash where the following keys are defined:
        role_id has a value which is a string
        role_description has a value which is a string
        genome_hits has a value which is an int
        blast_score has a value which is a float
        perc_identity has a value which is a float
        hit_location has a value which is a string


=end text



=item Description

find missing roles in a set of contigs

=back

=cut

sub missing_roles
{
    my $self = shift;
    my($workspace_name, $contigset_id, $genome_id, $genome_name) = @_;

    my @_bad_arguments;
    (!ref($workspace_name)) or push(@_bad_arguments, "Invalid type for argument \"workspace_name\" (value was \"$workspace_name\")");
    (!ref($contigset_id)) or push(@_bad_arguments, "Invalid type for argument \"contigset_id\" (value was \"$contigset_id\")");
    (!ref($genome_id)) or push(@_bad_arguments, "Invalid type for argument \"genome_id\" (value was \"$genome_id\")");
    (!ref($genome_name)) or push(@_bad_arguments, "Invalid type for argument \"genome_name\" (value was \"$genome_name\")");
    if (@_bad_arguments) {
        my $msg = "Invalid arguments passed to missing_roles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                                               method_name => 'missing_roles');
    }

    my $ctx = $SEEDtk::SEEDtkServer::CallContext;
    my($return);
    #BEGIN missing_roles
    my $token=$ctx->token;
    my $wshandle=Bio::KBase::workspace::Client->new($self->{'workspace-url'},token=>$token);
    my $fm=$wshandle->get_objects([{workspace=>$workspace_name,name=>$contigset_id}]);
    my $contigset = $fm->[0];
    my $helper = STKServices->new();
    $helper->connect_db();
    my $workDir = "$FIG_Config::data/$contigset_id";
    print "Working directory is $workDir.\n";
    my $mr = MissingRoles->new($contigset, undef, $helper, $workDir, 'warn' => 1,
            user => 'rastuser25', password => 'rastPASSWORD', genomeID => $genome_id,
            genomeName => $genome_name);
    # Process the contigs against the kmers.
    my $roles = $mr->Process("$FIG_Config::global/kmer_db.json");
    # Ask for the reactions.
    my $rolesToReactions = $helper->role_to_reactions([map { $_->[0] } @$roles]);
    # Output the missing roles.
    my @returnRoles;
    for my $role (@$roles) {
        # Get the role ID.
        my $roleID = $role->[0];
        # Get the reactions.
        my $reactionL = $rolesToReactions->{$roleID};
        my @reactions = map { { reaction_id => $_->[0], reaction_name => $_->[1] } } @$reactionL;
        # Create the output object.
        push @returnRoles, { role_id => $roleID, role_description => $role->[1],
            genome_hits => $role->[2], blast_score => $role->[3], perc_identity => $role->[4],
            hit_location => $role->[5], protein_sequence => $role->[6], reactions => \@reactions };
    }
    # Read the found roles.
    print "Collecting found roles.\n";
    my @foundRoles;
    open(my $ih, "<$workDir/genome.roles.tbl") || die "Could not open genome.roles.tbl: $!";
    while (! eof $ih) {
        my $line = <$ih>;
        chomp $line;
        my ($role_id, $role_description) = split /\t/, $line;
        push @foundRoles, {role_id => $role_id, role_description => $role_description};
    }
    # Read the close genomes.
    print "Collecting close genomes.\n";
    my @genomes;
    open(my $gh, "<$workDir/close.tbl") || die "Cound not open close.tbl: $!";
    while (! eof $gh) {
        my $line = <$gh>;
        chomp $line;
        my ($id, $hit_count, $name) = split /\t/, $line;
        push @genomes, {id => $id, hit_count => $hit_count, name => $name};
    }
    $return = { contigset_id => $contigset_id, missing_roles => \@returnRoles,
            close_genomes => \@genomes, found_roles => \@foundRoles };
    #END missing_roles
    my @_bad_returns;
    (ref($return) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
        my $msg = "Invalid returns passed to missing_roles:\n" . join("", map { "\t$_\n" } @_bad_returns);
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
                                                               method_name => 'missing_roles');
    }
    return($return);
}




=head2 version

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
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



=head2 MissingRoleItem

=over 4



=item Description

description of a role missing in the contigs


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


=end text

=back



=head2 MissingRoleData

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
contigset_id has a value which is a SEEDtk.contigset_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
roles has a value which is a reference to a list where each element is a SEEDtk.MissingRoleItem
contigset_id has a value which is a SEEDtk.contigset_id


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



=cut

1;
