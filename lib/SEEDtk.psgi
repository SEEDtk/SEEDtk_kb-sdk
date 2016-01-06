use SEEDtk::SEEDtkImpl;

use SEEDtk::SEEDtkServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = SEEDtk::SEEDtkImpl->new;
    push(@dispatch, 'SEEDtk' => $obj);
}


my $server = SEEDtk::SEEDtkServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
