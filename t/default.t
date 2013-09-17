use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use File::Temp 0.19; # newdir
use LWP::UserAgent;
use Test::TCP;

use Dancer2;
use Dancer2::Plugin::Auth::Tiny;

test_tcp(
  client => sub {
    my $port = shift;
    my $url  = "http://localhost:$port/";

    my $ua = LWP::UserAgent->new( cookie_jar => {} );

    my $res = $ua->get( $url . "public" );
    like $res->content, qr/index/i, "GET /public works";

    $res = $ua->get( $url . "private" );
    like $res->content, qr/login/i, "GET /private redirects to login";
    like $res->content, qr/${url}private/i, "GET /login knows to return to /private";

    $res = $ua->get( $url . "private" );
    like $res->content, qr/private/i, "GET /private now works";

    $res = $ua->get( $url . "logout" );
    like $res->content, qr/index/i, "GET /logout redirects to public";

    $res = $ua->get( $url . "private" );
    like $res->content, qr/login/i, "GET /private redirects to login again";
  },

  server => sub {
    my $port = shift;

    set confdir     => '.';
    set port        => $port, startup_info => 0;
    set show_errors => 1;
    set session     => 'Simple';

    get '/public' => sub { return 'index' };

    get '/private' => needs login => sub { return 'private' };

    get '/login' => sub {
      session "user" => "Larry Wall";
      return "login and to back to " . params->{return_url};
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
