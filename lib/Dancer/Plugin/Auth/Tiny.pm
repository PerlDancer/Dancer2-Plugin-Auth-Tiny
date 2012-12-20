use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Auth::Tiny;
# ABSTRACT: Require logged-in user for specified routes
# VERSION

use Carp qw/croak/;

use Dancer ':syntax';
use Dancer::Plugin;

my $conf;
my %dispatch = ( login => \&_build_login, );

register 'needs' => sub {
  my ( $self, $condition, @args ) = plugin_args(@_);

  my $builder = $dispatch{$condition};

  if ( ref $builder eq 'CODE' ) {
    return $builder->(@args);
  }
  else {
    croak "Unknown authorization condition '$condition'";
  }
};

sub extend {
  my ( $class, @args ) = @_;
  unless ( @args % 2 == 0 ) {
    croak "arguments to $class\->extend must be key/value pairs";
  }
  %dispatch = ( %dispatch, @args );
}

sub _build_login {
  my ($coderef) = @_;
  return sub {
    $conf ||= { _default_conf(), %{ plugin_setting() } }; # lazy
    if ( session $conf->{logged_in_key} ) {
      goto $coderef;
    }
    else {
      my $query_params = params("query");
      my $data =
        { $conf->{callback_key} => uri_for( request->path, $query_params ) };
      for my $k ( @{ $conf->{passthrough} } ) {
        $data->{$k} = params->{$k} if params->{$k};
      }
      return redirect uri_for( $conf->{login_route}, $data );
    }
  };
}

sub _default_conf {
  return (
    login_route   => '/login',
    logged_in_key => 'user',
    callback_key  => 'return_url',
    passthrough   => [qw/user/],
  );
}

register_plugin for_versions => [ 1, 2 ];

1;

=for Pod::Coverage extend

=head1 SYNOPSIS

  use Dancer::Plugin::Auth::Tiny;

  get '/private' => needs login => sub { ... };

  get '/login' => sub {
    # put 'return_url' in a hidden form field
    template 'login' => { return_url => params->{return_url} };
  };

  post '/login' => sub {
    if ( _is_valid( params->{user}, params->{password} ) ) {
      session user => params->{user},
      return redirect params->{return_url} || '/';
    }
    else {
      template 'login' => { error => "invalid username or password" };
    }
  };

  sub _is_valid { ... } # this is up to you

=head1 DESCRIPTION

This L<Dancer> plugin provides an extremely simple way of requiring that a user
be logged in before allowing access to certain routes.

It is not "Tiny" in the usual CPAN sense, but it is "Tiny" with respect to
Dancer authentication plugins.  It provides very simple sugar to wrap route
handlers with an authentication closure.

The plugin provides the C<needs> keyword and a default C<login> wrapper that
you can use like this:

  get '/private' => needs login => $coderef;

The code above is roughly equivalent to this:

  get '/private' => sub {
    if ( session 'user' ) {
      goto $coderef;
    }
    else {
      return redirect uri_for( '/login',
        { return_url => uri_for( request->path, request->params ) } );
    }
  };

It is up to you to provide the '/login' route, handle actual authentication,
and set C<user> session variable if login is successful.

If the original request contains a parameter in the C<passthrough> list, it
will be added to the login query. For example,
C<http://example.com/private?user=dagolden> will be redirected as
C<http://example.com/login?user=dagolden&return_url=...>.  This facilitates
pre-populating a login form.

=head1 CONFIGURATION

You may override any of these settings:

=for :list
* C<login_route: /login> -- defines where a protected route is redirected
* C<logged_in_key: user> -- defines the session key that must be true to indicate a logged-in user
* C<callback_key: return_url> -- defines the parameter key with the original request URL that is passed to the login route
* C<passthrough: - user> -- a list of params that should be passed through to the login handler

=head1 EXTENDING

The class method C<extend> may be used to add (or override) authentication
criteria. For example, to add a check for the C<session 'is_admin'> key:

  Dancer::Plugin::Auth::Tiny->extend(
    admin => sub {
      my ($coderef) = @_;
      return sub {
        if ( session "is_admin" ) {
          goto $coderef;
        }
        else {
          redirect '/access_denied';
        }
      };
    }
  );

  get '/super_secret' => needs admin => sub { ... };

It takes key/value pairs where the value must be a closure generator that wraps
arguments passed to C<needs>.

You could pass additional arguments before the code reference like so:

  # don't conflict with Dancer's any()
  use Syntax::Keyword::Junction 'any' => { -as => 'any_of' };

  Dancer::Plugin::Auth::Tiny->extend(
    any_role => sub {
      my $coderef = pop;
      my @requested_roles = @_;
      return sub {
        my @user_roles = @{ session("roles") || [] };
        if ( any_of(@requested_roles) eq any_of(@user_roles) {
          goto $coderef;
        }
        else {
          redirect '/access_denied';
        }
      };
    }
  );

  get '/parental' => needs any_role => qw/mom dad/ => sub { ... };

=head1 SEE ALSO

For more complex L<Dancer> authentication, see:

=for :list
* L<Dancer::Plugin::Auth::Extensible>
* L<Dancer::Plugin::Auth::RBAC>

For password authentication algorithms for your own '/login' handler, see:

=for :list
* L<Auth::Passphrase>
* L<Dancer::Plugin::Passphrase>

=head1 ACKNOWLEDGMENTS

This simplified Auth module was inspired by Dancer::Plugin::Auth::Extensible by
David Precious and discussions about its API by member of the Dancer Users
mailing list.

=cut

# vim: ts=2 sts=2 sw=2 et:
