package Config::MVP::Reader::INI;
use Moose;
with 'Config::MVP::Reader::Findable::ByExtension';
# ABSTRACT: an MVP config reader for .ini files

use Config::MVP 0.101440; # new reader interface

=head1 DESCRIPTION

Config::MVP::Reader::INI reads F<.ini> files containing MVP-style
configuration.

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
  use base 'Config::INI::Reader';

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
    unless ($self->assembler->current_section) {
      my $starting_name = $self->starting_section;

      if ($self->assembler->sequence->section_named( $starting_name )) {
        Carp::croak q{can't set value outside of section once starting }
                  . q{section exists};
      }

      $self->assembler->change_section(\undef, $starting_name);
    }

    $self->assembler->add_value($name, $value);
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
