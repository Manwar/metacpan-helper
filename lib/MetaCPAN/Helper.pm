package MetaCPAN::Helper;

use 5.006;
use strict;
use warnings;
use Moo;
use Carp;

has client => (
    is => 'ro',
    default => sub {
        require MetaCPAN::Client;
        return MetaCPAN::Client->new();
    },
);

sub module2dist
{
    my ($self, $module_name) = @_;
    my $query      = { all => [
                           {        status => 'latest'     },
                           {      maturity => 'released'   },
                           { 'module.name' => $module_name },
                       ]
                     };
    my $params     = { fields => [qw(distribution)] };
    my $result_set = $self->client->module($query, $params) || return undef;
    my $module     = $result_set->next                      || return undef;

    return $module->distribution || undef;
}

sub dist2releases {
    my $self      = shift;
    my $dist_name = shift;
    $dist_name and !ref($dist_name)
        or croak "invalid distribution name value";

    my $filter   = { distribution => $dist_name };
    my $releases = $self->client->release($filter);

    return $releases;
}

sub dist2latest_release {
    my $self      = shift;
    my $dist_name = shift;
    $dist_name and !ref($dist_name)
        or croak "invalid distribution name value";

    my $filter = {
        all => [
            { distribution => $dist_name },
            { status       => "latest" }
        ]
    };

    my $release = $self->client->release($filter);

    return ( $release->total == 1 ? $release->next : undef );
}

1;

=head1 NAME

MetaCPAN::Helper - a MetaCPAN client that provides some high-level helper functions

=head1 SYNOPSIS

 use MetaCPAN::Helper;

 my $helper   = MetaCPAN::Helper->new();
 my $module   = 'MetaCPAN::Client';
 my $distname = $helper->module2dist($module);
 print "$module is in dist '$distname'\n";

=head1 DESCRIPTION

This module is a helper class built on top of L<MetaCPAN::Client>,
providing methods which provide simple high-level functions for answering
common "CPAN lookup questions".

B<Note>: this is an early release, and the interface is likely to change.
Feedback on the interface is very welcome.

You could just use L<MetaCPAN::Client> directly yourself,
which might make sense in a larger application.
This class is aimed at people writing smaller one-off scripts.

=head1 METHODS

=head2 module2dist( $MODULE_NAME )

Takes the name of a module, and returns the name of the distribution which
I<currently> contains that module, according to the MetaCPAN API.

At the moment this will ignore any developer releases,
and take the latest non-developer release of the module.

If the distribution name in the dist's metadata doesn't match the
name produced by L<CPAN::DistnameInfo>, then be aware that this method
returns the name according to C<CPAN::DistnameInfo>.
This doesn't happen very often (less than 0.5% of CPAN distributions).

=head2 dist2releases( $DIST_NAME )

Takes the name of a distribution, and returns the L<MetaCPAN::Client::ResultSet>
iterator of all releases (as L<MetaCPAN::Client::Release> objects)
associated with that distribution.

=head2 dist2latest_release( $DIST_NAME )

Takes the name of a distribution, and returns the L<MetaCPAN::Client::Release>
object of the "latest" release of that distribution.

=head1 SEE ALSO

L<MetaCPAN::Client> - the definitive client for querying L<MetaCPAN|https://metacpan.org>.

=head1 REPOSITORY

L<https://github.com/CPAN-API/metacpan-helper>

=head1 CONTRIBUTORS

L<Neil Bowers|https://metacpan.org/author/NEILB>
L<Mickey Nasriachi|https://metacpan.org/author/MICKEY>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 the MetaCPAN project.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

