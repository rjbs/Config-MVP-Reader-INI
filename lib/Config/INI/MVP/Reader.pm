package Config::INI::MVP::Reader;
use Moose;

use Config::INI::Reader;
BEGIN { our @ISA; push @ISA, 'Config::INI::Reader' }
sub new { goto &Moose::Object::new }

use Config::MVP::Assembler;

=head1 NAME

Config::INI::MVP::Reader - multi-value capable .ini file reader (for plugins)

=head1 VERSION

version 0.023

=cut

our $VERSION = '0.023';

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
default C<mvp_multivalue_args>) on it, to determine which property names may
have multiple entries.  If the return value of that method includes C<y>, then
the entry for C<y> in the Foo::Bar section will be an arrayref with two values.
If the list returned by C<multivalue_args> did not contain C<y>, then an
exception would be raised while reading this section.

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

=cut

has assembler => (
  is   => 'ro',
  isa  => 'Config::MVP::Assembler',
  default => sub {
    my ($self) = @_;
    my $assembler = $self->assembler_class->new;

    my $starting_section = $assembler->section_class->new({
      name    => $self->starting_section_name,
      aliases => $self->starting_section_aliases,
      multivalue_args => $self->starting_section_multivalue_args,
    });

    $assembler->sequence->add_section($starting_section);

    return $assembler;
  },
);

has assembler_class => (
  is   => 'ro',
  isa  => 'ClassName',
  lazy => 1,
  builder => 'default_assembler_class',
);

sub default_assembler_class { 'Config::MVP::Assembler' }

# XXX: These should be attributes with builders and blah blah blah, but I just
# can't be bothered. -- rjbs, 2009-07-24
sub starting_section_name    { $_[0]->starting_section }
sub starting_section_aliases { {} }
sub starting_section_multivalue_args { [] }

sub change_section {
  my ($self, $section) = @_;

  my ($package, $name) = $section =~ m{\A\s*(?:([^/\s]+)\s*/\s*)?(\S+)\z};
  $package = $name unless defined $package and length $package;
    
  Carp::croak qq{couldn't understand section header: "$_[1]"}
    unless $package;

  $self->assembler->change_section($package, $name);
}

sub finalize {
  my ($self) = @_;

  my @sections;

  for my $section ($self->assembler->sequence->sections) {
    push @sections, {
      %{ $section->payload },
      '=name' => $section->name,
      ($section->package ? ('=package' => $section->package) : ()),
    };
  }

  $self->{data} = \@sections;
}

sub set_value {
  my ($self, $name, $value) = @_;
  $self->assembler->add_value($name, $value);
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

