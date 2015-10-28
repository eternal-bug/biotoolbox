package Bio::ToolBox::SeqFeature;
our $VERSION = '1.35';

=head1 NAME

Bio::ToolBox::SeqFeature - Fast, simple SeqFeature implementation

=head1 DESCRIPTION

SeqFeature objects represent functional elements on a genomic or chromosomal 
sequence, such as genes, transcripts, exons, etc. In many cases, especially 
genes, they have a hierarchical structure, typically in this order

    gene
      mRNA or transcript
        CDS
        exon

SeqFeature objects have at a minimum coordinate information, including 
chromosome, start, stop, and strand, and a name or unique identifier. They 
often also have type or source information, which usually follows the 
Sequence Ontology key words 

This is a fast, efficient, simplified SeqFeature implementation that mostly 
implements the L<Bio::SeqFeatureI> API, and could be substituted in for other 
implementations, such L<Bio::SeqFeature::Lite> and L<Bio::SeqFeature::Generic>. 
Unlike the others, however, it inherits no methods and uses an unorthodox 
blessed array to store feature attributes. 

=head1 LIMITATIONS

Because of their underlying array structure, Bio::ToolBox::SeqFeature objects 
should generally not be used as a base class (unless you know the ramifications 
of doing so). The following Bio classes and Interfaces may not work, either because 
they have not been implemented, object structure incompatibility, or simply haven't 
been tested yet for compatibility (it's possible some can be used).

=over 4

=item Bio::AnnotationI

=item Bio::LocationI

=item Bio::RangeI

=item Bio::SeqI

=item Bio::Tools::GFF

=item Bio::DB::SeqFeature::Store

=item Bio::Graphics

=back

=head1 METHODS





=cut

use strict;
use Carp qw(carp cluck croak confess);
use constant {
	SEQID   => 0,
	START   => 1,
	STOP    => 2,
	STRND   => 3,
	ID      => 4,
	NAME    => 5,
	TYPE    => 6,
	SRC     => 7,
	SCORE   => 8,
	PHASE   => 9,	
	SUBF    => 10,
	ATTRB   => 11,
};
our $IDCOUNT = 0;

1;

#### Aliases ####
# to maintain compatibility with Bio::SeqFeature::Lite and Bio::SeqFeatureI we 
# put in plenty of aliases to some of the methods
*stop = \&end;
*name = \&display_name;
*id = \&display_name;
*method = \&primary_tag;
*source = \&source_tag;
*add_segment = \&add_SeqFeature;
*get_all_SeqFeatures = *segments = \&get_SeqFeatures;
*each_tag_value = \&get_tag_values;
*get_all_tags = \&all_tags;


#### METHODS ####
sub new {
	my $class = shift;
	if (ref($class)) {
		$class = ref($class);
	}
	my %args = @_;
	my $self = bless [], $class; 
		# bless ourselves early to take advantage of some methods
		# but otherwise do what we can simply and quickly
	
	# required options
	$self->[SEQID] = $args{-seq_id} || $args{-seqid} || $args{'-ref'} || 
		$args{chrom} || undef;
	$self->[START] = $args{-start} || undef;
	$self->[STOP] = $args{-end} || $args{-stop} || undef;
	$self->strand( $args{-strand} || 0);
	$self->[ID] = $args{-primary_id} || $args{-id} || 
		sprintf("Feat%s%09d", $$, $IDCOUNT++);
		# default ID is based on program pid and an incrementing counter
		# IDs must be unique within the scope of a database, unlike name field
	$self->[NAME] = $args{-display_name} || $args{-name} || $self->[ID];
	
	# sanity check
	unless (defined $self->[SEQID] and defined $self->[START] and defined $self->[STOP]) {
		cluck "$class new method should contain at minimum seq_id, start, end";
	}
	if ($self->[START] > $self->[STOP]) {
		# flip the coordinates around
		my $start = $self->[START];
		my $end = $self->[STOP];
		$self->[STOP] = $start;
		$self->[START] = $end;
		$self->[STRND] *= -1;
	}
	
	# additional options
	$args{-type} ||= $args{-primary_tag} || undef;
	if (defined $args{-type}) {
		$self->type($args{-type});
	}
	$args{-source} ||= $args{-source_tag} || undef;
	if (defined $args{-source}) {
		$self->[SRC] = $args{-source};
	}
	if (exists $args{-score}) {
		$self->[SCORE] = $args{-score};
	}
	if (exists $args{-phase}) {
		$self->phase($args{-phase});
	}
	if (exists $args{-attributes} or exists $args{-tags}) {
		$args{-attributes} ||= $args{-tags};
		if (ref($args{-attributes}) eq 'HASH') {
			$self->[ATTRB] = $args{-attributes};
		}
	}
	if (exists $args{-segments}) {
		$self->[SUBF] = [];
		foreach my $s (@{ $args{-segments} }) {
			unless (ref($s) eq $class) {
				croak "segments should be passed as $class objects!";
			}
			push @{$self->[SUBF]}, $s;
		}
	}
	
	return $self; 
}


sub seq_id {
	my $self = shift;
	if (@_) {
		$self->[SEQID] = $_[0];
	}
	return $self->[SEQID];
}

sub start {
	my $self = shift;
	if (@_) {
		$self->[START] = $_[0];
	}
	return $self->[START];
}

sub end {
	my $self = shift;
	if (@_) {
		$self->[STOP] = $_[0];
	}
	return $self->[STOP];
}

sub strand {
	my $self = shift;
	if (@_) {
		$self->[STRND] = $_[0];
		$self->[STRND] = 1 if $self->[STRND] eq '+';
		$self->[STRND] = -1 if $self->[STRND] eq '-';
		$self->[STRND] = 0 if $self->[STRND] eq '.';
	}
	$self->[STRND] ||= 0;
	return $self->[STRND];
}

sub display_name {
	my $self = shift;
	if (@_) {
		$self->[NAME] = $_[0];
	}
	return $self->[NAME];
}

sub primary_id {
	my $self = shift;
	if (@_) {
		$self->[ID] = $_[0];
	}
	return $self->[ID];
}

sub primary_tag {
	my $self = shift;
	if (@_) {
		$self->[TYPE] = $_[0];
	}
	$self->[TYPE] ||= 'region';
	return $self->[TYPE];
}

sub source_tag {
	my $self = shift;
	if (@_) {
		$self->[SRC] = $_[0];
	}
	$self->[SRC] ||= undef;
	return $self->[SRC];
}

sub type {
	my $self = shift;
	if (@_) {
		my $type = $_[0];
		if ($type =~ /:/) {
			my ($t, $s) = split /:/, $type;
			$self->[TYPE] = $t;
			$self->[SRC] = $s;
		}
		else {
			$self->[TYPE] = $type;
		}
	}
	$self->[TYPE] ||= undef;
	$self->[SRC] ||= undef;
	if (defined $self->[SRC]) {
		return join(':', $self->[TYPE], $self->[SRC]);
	}
	return $self->[TYPE];
}

sub score {
	my $self = shift;
	if (@_) {
		$self->[SCORE] = $_[0];
	}
	$self->[SCORE] ||= 0;
	return $self->[SCORE];
}

sub phase {
	my $self = shift;
	if (@_) {
		my $p = $_[0];
		unless ($p =~ /^[012]$/) {
			cluck "phase must be 0, 1, 2 or .!";
		}
		$self->[PHASE] = $p;
	}
	$self->[PHASE] ||= '.';
	return $self->[PHASE];
}

sub add_SeqFeature {
	my $self = shift;
	$self->[SUBF] ||= [];
	my $count = 0;
	foreach my $s (@_) {
		if (ref($s)) {
			push @{ $self->[SUBF] }, $s;
			$count++;
		}
		else {
			cluck "please use Seqfeature objects when adding sub features!";
		}
	}
	return $count;
}

sub get_SeqFeatures {
	my $self = shift;
	$self->[SUBF] ||= [];
	return @{ $self->[SUBF] };
}

sub add_tag_value {
	my ($self, $key, $value) = @_;
	return unless ($key and $value);
	$self->[ATTRB] ||= {};
	if (exists $self->[ATTRB]->{$key}) {
		if (ref($self->[ATTRB]->{$key}) eq 'ARRAY') {
			push @{ $self->[ATTRB]->{$key} }, $value;
		}
		else {
			my $current = $self->[ATTRB]->{$key};
			$self->[ATTRB]->{$key} = [$current, $value];
		}
	}
	else {
		$self->[ATTRB]->{$key} = $value;
	}
}

sub has_tag {
	my ($self, $key) = @_;
	$self->[ATTRB] ||= {};
	return exists $self->[ATTRB]->{$key};
}

sub get_tag_values {
	my ($self, $key) = @_;
	$self->[ATTRB] ||= {};
	if (exists $self->[ATTRB]->{$key}) {
		if (ref($self->[ATTRB]->{$key}) eq 'ARRAY') {
			return wantarray ? @{ $self->[ATTRB]->{$key} } : $self->[ATTRB]->{$key};
		}
		else {
			return $self->[ATTRB]->{$key};
		}
	}
	else {
		return;
	}
}

sub attributes {
	my $self = shift;
	$self->[ATTRB] ||= {};
	return wantarray ? @{ $self->[ATTRB] } : $self->[ATTRB];
}

sub all_tags {
	my $self = shift;
	$self->[ATTRB] ||= {};
	my @k = keys %{ $self->[ATTRB] };
	return wantarray ? @k : \@k;
}

sub length {
	my $self = shift;
	return $self->end - $self->start + 1;
}


__END__

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.  