use strict;
use warnings;

package Config::INI::MVP::Reader;
use base qw(Config::INI::Reader);

=head1 NAME

Config::INI::MVP::Reader - multi-value capable .ini file reader (for plugins)

=head1 VERSION

version 0.019

=cut

our $VERSION = '0.019';

=head1 DESCRIPTION

The MVP INI file reader reads INI files, but can handle properties with
multiple values.  The identification of properties that may have multiple
entries is done by section, on a plugin basis.  For example, given the
following file:

  [Foo::Bar]
  x = 1
  y = 2
  y = 3

MVP will, upon reaching this section, load Foo::Bar and call a method (by
default C<multivalue_args>) on it, to determine which property names may have
multiple entries.  If the return value of that method includes C<y>, then the
entry for C<y> in the Foo::Bar section will be an arrayref with two values.  If
the list returned by C<multivalue_args> did not contain C<y>, then an exception
would be raised while reading this section.

To request a single plugin multiple times, the sections must be uniquely
identifiable by their names.  A name can be given in this form:

  [Package::Name / name]

If no name is given, the package name is used as the name.

The data returned is in the form:

  [
    {
      '=package' => 'Some::Package',
      '=name'    => 'plugin_moniker',
      arg_1_val  => $value,
      arg_N_val  => [ $val1, $val2, ... ],
    },
    ...
  ]

The unfortunate names C<=package> and C<=name> are used because they are
illegal as property names.  The first datum may be the "root" section before
any section header.  By default, it will have the name C<_> and no package.

=head1 METHODS

=head2 multivalue_args

This method returns a list of property names which may have multiple entries in
the root section.

=cut

sub new {
  my ($class) = @_;

  my $self = bless { } => $class;

  $self->{__PACKAGE__} = {
    mva    => { $self->starting_section => [ $self->multivalue_args ] },
    order  => [ $self->starting_section ],
    # plugin => { $self->starting_section => { } },
  };

  return $self;
}

sub multivalue_args { }

sub starting_section { q{_} }

sub _expand_package { $_[1] }

sub change_section {
  my ($self, $section) = @_;

  my ($package, $name) = $section =~ m{\A\s*(?:([^/\s]+)\s*/\s*)?(\S+)\z};
  $package = $name unless defined $package and length $package;
  
  Carp::croak qq{couldn't understand section header: "$section"}
    unless $package;

  $package = $self->_expand_package($package);

  # Consider using Params::Util to validate class name.  -- rjbs, 2007-05-11
  Carp::croak "invalid package name '$package' in configuration"
    unless $package =~ /\A[A-Z0-9]+(?:::[A-Z0-9]+)*\z/i;
  
  Carp::croak qq{multiple sections found for plugin "$name"}
    if $self->{__PACKAGE__}{plugin}{$name};

  my $plugin = $self->{__PACKAGE__}{plugin}{$name} = {
    '=package' => $package
  };

  push @{ $self->{__PACKAGE__}{order} }, $name;
  $self->{section} = $name;

  # We already inspected this plugin.
  return if $self->{__PACKAGE__}{mva}{$package};

  eval "require $package; 1"
    or Carp::croak "couldn't load plugin $section given in config: $@";

  if ($package->can('multivalue_args')) {
    $self->{__PACKAGE__}{mva}{$package} = [ $package->multivalue_args ];
  } else {
    $self->{__PACKAGE__}{mva}{$package} = [ ];
  }
}

sub set_value {
  my ($self, $name, $value) = @_;

  my $sec_name = $self->current_section;
  my $section = $self->{__PACKAGE__}{plugin}{ $sec_name } ||= {};

  my $mva = $sec_name eq $self->starting_section
          ? $self->{__PACKAGE__}{mva}{ $sec_name}
          : $self->{__PACKAGE__}{mva}{ $section->{'=package'} };

  if (grep { $_ eq $name } @$mva) {
    $section->{$name} ||= [];
    push @{ $section->{$name} }, $value;
    return;
  }

  if (exists $section->{$name}) {
    Carp::croak "multiple values given for property $name in section $sec_name";
  }

  $section->{$name} = $value;
}

sub finalize {
  my ($self) = @_;

  my $data = $self->{data} = [ ];
  for my $name (@{ $self->{__PACKAGE__}{order} }) {
    my $plugin = $self->{__PACKAGE__}{plugin}{$name};
    $plugin->{'=name'} = $name;
    push @$data, $plugin;
  }
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2008 Ricardo SIGNES, all rights reserved.

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

1;

