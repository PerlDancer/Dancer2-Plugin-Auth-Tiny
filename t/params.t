use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use File::Temp 0.19; # newdir
use LWP::UserAgent;
use Test::TCP;

test_tcp(
  client => sub {
    my $port = shift;
    my $url  = "http://localhost:$port/";

    my $ua = LWP::UserAgent->new( cookie_jar => {} );
    push @{ $ua->requests_redirectable }, 'POST';

    my $res = $ua->get( $url . "public" );
    like $res->content, qr/index/i, "GET /public works";

    $res = $ua->post( $url . "private", { foo => 'bar', user => 'Larry' } );
    like $res->content, qr/params:\s*$/i,
      "POST /private doesn't leak post params in redirect"
        or diag explain $res;

    $res = $ua->post( $url . "private", { foo => 'bar' } );
    like $res->content, qr/params: foo:bar/i,
      "POST /private after login has parameters";
  },

  server => sub {
    my $port = shift;

    use Dancer2;
    use Dancer2::Plugin::Auth::Tiny;

    set confdir     => '.';
    set port        => $port, startup_info => 0;
    set show_errors => 1;
    set session     => 'Simple';

    get '/public' => sub { return 'index' };

    any [qw/get post/] => '/private' => needs login =>
      sub { return "params: " . join( ":", params ) };

    get '/login' => sub {
      session "user" => params->{user};
      redirect params->{return_url}, 303;
    };

    get '/logout' => sub {
      context->destroy_session;
      redirect uri_for('/public');
    };

    Dancer2->runner->server->port($port);
    start;
  },
);

done_testing;
# COPYRIGHT
