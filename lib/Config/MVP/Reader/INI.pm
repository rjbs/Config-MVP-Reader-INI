package Config::MVP::Reader::INI;
use Moose;
with 'Config::MVP::Reader::Findable::ByExtension';

# ABSTRACT: an MVP config reader for .ini files

use Config::INI::MVP::Reader;

=head1 VERSION

version 0.024

=cut

our $VERSION = '0.024';

=head1 DESCRIPTION

Config::MVP::Reader::INI reads F<.ini> files containing MVP-style
configuration.  It uses L<Config::INI::MVP::Reader> to do most of the heavy
lifting.

=cut

# Clearly this should be an attribute with a builder blah blah blah. -- rjbs,
# 2009-07-25
sub default_extension { 'ini' }

sub read_into_assembler {
  my ($self, $location, $assembler) = @_;

  my $reader = Config::MVP::Reader::INI::INIReader->new($assembler);
  $reader->read_file($location);

  return $assembler->sequence;
}

{
  package
   Config::MVP::Reader::INI::INIReader;
  use Config::INI::Reader;
  BEGIN { our @ISA; push @ISA, 'Config::INI::Reader' }

  sub new {
    my ($class, $assembler) = @_;
    my $self = $class->SUPER::new;
    $self->{assembler} = $assembler;
    return $self;
  }

  sub assembler { $_[0]{assembler} }

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

    $self->assembler->finalize;
  }

  sub set_value {
    my ($self, $name, $value) = @_;
    $self->assembler->add_value($name, $value);
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


no Moose;
__PACKAGE__->meta->make_immutable;
1;
