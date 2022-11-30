#!/usr/bin/perl
###
### @author Simone Marchi <simone.marchi(at)ilc.cnr.it>
###
use strict;
use warnings;
use v5.10; # for say() function
use Getopt::Std;
use DBI;
use Config::Simple;


my $DEBUG = 0;

# MySQL database configuration
my $cfg = new Config::Simple('app.cfg');

# MySQL database configuration
my $dsn = $cfg->param('mysql.dsn');
my $username = $cfg->param('mysql.username');
my $password = $cfg->param('mysql.password');

my $redundantUsem = $cfg->param('mysql.redundantusem');
my $redundantUsyn = $cfg->param('mysql.redundantusyn');

# declare the perl command line flags/options we want to allow
my %options=();
getopts("a:cdehrox:st:mS:", \%options);

my $useComment = 0;
my $useDefinition = 0;
my $useExemple = 0;
my $useRefTable = 0;
my $refTable = "";
my $useMus = 0;
my $outputOnFiles = 0;
my $output;
my $onTable;
my $automatic = 0;

### PARSING ARGUMENTS

if (defined $options{h}) {
    &usage();
    exit;
}

if (!defined $options{a}) { ## NOT Automatic discovery
    if (defined $options{t}) {
	if (($options{t} eq "usem") or ($options{t} eq "usyn" )) {
	    $onTable = $options{t};
	} else {
	    die "You have to use 'usem' or 'usyn' in -t option\n";
	}
    } else {
	print STDERR "You must specify \"-t [usem|usyn]\" option at least\n\n";
	&usage();
	exit;
    }

    if (defined $options{c}) {
	$useComment = 1;
    }
    if (defined $options{d}) {
	$useDefinition = 1;
    }
    if (defined $options{e}) {
	$useExemple = 1;
    }
    if (defined $options{r}) {
	$useRefTable = 1;
	if ($onTable eq "usem") {
	    $refTable = "usyn";
	} else {
	    $refTable = "usem";
	}
    }
    if (defined $options{m}) {
	if ($onTable eq "usyn") {
	    $useMus = 1;

	} else {
	    die "Remove -m option\n";
	}
    }
} else { ## Automatic discovery
    $onTable = $options{a};
    $automatic = 1;
}

if (defined $options{s}) {
    &cleanRedundantTables($onTable);
}

if (defined $options{x}) {
    $DEBUG = $options{x};
}

if (defined $options{o}) {
    #     open( $output, '>', $options{o} );
    $outputOnFiles = 1;
}

### END PARSING ARGUMENTS

if ($automatic == 1) {
    if ($onTable eq "usem") {

	#&findUsemCanditateRedundant($useComment, $useDefinition, $useExemple, $useRefTable);
	&findUsemCanditateRedundant(0, 0, 0, 0);
	&findUsemCanditateRedundant(1, 0, 0, 0);
	&findUsemCanditateRedundant(0, 1, 0, 0);
	&findUsemCanditateRedundant(1, 1, 0, 0);
	&findUsemCanditateRedundant(0, 0, 1, 0);
	&findUsemCanditateRedundant(1, 0, 1, 0);
	&findUsemCanditateRedundant(0, 1, 1, 0);
	&findUsemCanditateRedundant(1, 1, 1, 0);
	&findUsemCanditateRedundant(0, 0, 0, 1);
	&findUsemCanditateRedundant(1, 0, 0, 1);
	&findUsemCanditateRedundant(0, 1, 0, 1);
	&findUsemCanditateRedundant(1, 1, 0, 1);
	&findUsemCanditateRedundant(0, 0, 1, 1);
	&findUsemCanditateRedundant(1, 0, 1, 1);
	&findUsemCanditateRedundant(0, 1, 1, 1);
	&findUsemCanditateRedundant(1, 1, 1, 1);

    } elsif ($onTable eq "usyn"){
#	&findUsynCanditateRedundant($useMus, $useExemple, $useComment, $useRefTable);

	&findUsynCanditateRedundant(0, 0, 0, 0);
	&findUsynCanditateRedundant(0, 0, 0, 1);
	&findUsynCanditateRedundant(0, 0, 1, 0);
	&findUsynCanditateRedundant(0, 0, 1, 1);
	&findUsynCanditateRedundant(0, 1, 0, 0);
	&findUsynCanditateRedundant(0, 1, 0, 1);
	&findUsynCanditateRedundant(0, 1, 1, 0);
	&findUsynCanditateRedundant(0, 1, 1, 1);
	&findUsynCanditateRedundant(1, 0, 0, 0);
	&findUsynCanditateRedundant(1, 0, 0, 1);
	&findUsynCanditateRedundant(1, 0, 1, 0);
	&findUsynCanditateRedundant(1, 0, 1, 1);
	&findUsynCanditateRedundant(1, 1, 0, 0);
	&findUsynCanditateRedundant(1, 1, 0, 1);
	&findUsynCanditateRedundant(1, 1, 1, 0);
	&findUsynCanditateRedundant(1, 1, 1, 1);
    } else {
	print STDERR "ERR: Unknown $onTable table\n\n";
	&usage();
	exit;
    }
} else {
    if ($onTable eq "usem") {
	&findUsemCanditateRedundant($useComment, $useDefinition, $useExemple, $useRefTable);
    } else {
	&findUsynCanditateRedundant($useComment, $useMus, $useExemple,  $useRefTable);
    }
}

sub getDBConnection () {

    # connect to MySQL database
    my %attr = ( AutoCommit=>0,
		 PrintError=>0,  # turn off error reporting via warn()
		 RaiseError=>1);   # turn on error reporting via die()

    my $dbhandler = DBI->connect($dsn,$username,$password, \%attr) or die;

    return $dbhandler;
}

sub cleanRedundantTables() {
    my ($origTable) = @_; #usyns o usem
    #svuoto le tabelle dei ridondanti
    print STDERR "cleanRedundantTables(): Delete from $origTable\n";# if($DEBUG > 0);
    my $dbh = &getDBConnection();
    my $tableToDelete = "";

    if ($origTable eq "usyn") {
	$tableToDelete = $redundantUsyn;
    } elsif($origTable eq "usem") {
	$tableToDelete = $redundantUsem;
    } else {
	die "Unkown table (" .$origTable . ")\n";
    }

    my $stmt = $dbh->prepare("DELETE FROM " . $tableToDelete);
    $stmt->execute() or die;
    $stmt->finish;
    $dbh->commit or die $dbh->errstr;
    $dbh->disconnect;
}

### Check if is already present a redundancy with type $status for the ID $id in table $table
sub isAlreadyInRedundantTable () {

    my ($dbh, $table, $id, $idName, $status) = @_;

    my $sth = $dbh->prepare("SELECT COUNT(*) FROM " . $table . " WHERE " . $idName . " = ? AND status = ?")
	or die "Couldn't prepare statement: " . $dbh->errstr;

    $sth->execute($id, $status)  # Execute the query
	or die "Couldn't execute statement: " . $sth->errstr;

    my @data = $sth->fetchrow_array();

    if ($data[0]) {
	print STDERR "\t$id isAlreadyInRedundantTable in $table with type $status : how many @data\n"  if ($DEBUG > 2) ;
    }

    return $data[0];

}

#convert binary to decimal value
sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}


sub findUsemCanditateRedundant () {

    my ($useComment, $useDefinition, $useExemple, $useRefTable) = @_;

    my $status = &bin2dec($useRefTable.$useExemple.$useDefinition.$useComment);
    my $refTable = "";
    if ($useRefTable) {
	$refTable = "usyn";
    }


    if($outputOnFiles == 1) {
	my $filename = &outputFileName($useComment, $useDefinition, $onTable, $useMus, $useExemple, $refTable, $status);
	open( $output, '>', $filename ) or die("Unable to create/open $filename");
    }
    print STDERR "status: " . $status . "\n" if ($DEBUG > 0);
    my $sqlString = "SELECT DISTINCT a.idUsem, b.idUsem, a.naming ".
	"FROM usem a, usem b ".
	"WHERE a.naming = b.naming ".
	"AND a.pos = b.pos ";
    if ($useComment)  {
	$sqlString .= "AND COALESCE(a.comment,'') = COALESCE(b.comment,'') ";
    }
    if ($useDefinition)  {
	$sqlString .= "AND COALESCE(a.definition,'') = COALESCE(b.definition,'') ";
    }
    if ($useExemple)  {
	$sqlString .= "AND COALESCE(a.exemple,'') = COALESCE(b.exemple,'') ";
    }

    $sqlString .= "AND a.idUsem < b.idUsem ".
	# "and a.naming like '%disgraziato'".
	"order by a.naming";

    my $dbh = &getDBConnection();

    my $sth = $dbh->prepare($sqlString)
	or die "prepare statement failed: $dbh->errstr()";

    $sth->execute() or die "execution failed: $dbh->errstr()";
    my $inserted = 0;
    while (my ($idUsemA, $idUsemB, $naming) = $sth->fetchrow_array) {

	print STDERR ">> $naming, $idUsemA, $idUsemB\n" if ($DEBUG > 0);
	my @traitsA = &selectTraits($dbh, $idUsemA);
	my @traitsB = &selectTraits($dbh, $idUsemB);

	print STDERR "TRAITS: " . scalar(@traitsA) . " " . scalar(@traitsB)."\n" if ($DEBUG > 2);
	if ( &compareArray(\@traitsA, \@traitsB) == 1) {
	    print STDERR "$idUsemB is potential redundant of $idUsemA\n\n" if ($DEBUG > 2);
	    my @templatesA = &selectTemplates($dbh, $idUsemA);
	    my @templatesB = &selectTemplates($dbh, $idUsemB);

	    print STDERR "TEMPLATES: " . scalar(@templatesA) . " " . scalar(@templatesB)."\n" if ($DEBUG > 3);
	    if (&compareArray(\@templatesA, \@templatesB) == 1) {
		my @predicateA = &selectPredicate($dbh, $idUsemA);
		my @predicateB = &selectPredicate($dbh, $idUsemB);

		print STDERR "PREDICATES: " . scalar(@predicateA) . " " . scalar(@predicateB)."\n" if ($DEBUG > 3);
		if (&compareArray(\@predicateA, \@predicateB) == 1) {
		    my @semrelA = &selectSemRel($dbh, $idUsemA);
		    my @semrelB = &selectSemRel($dbh, $idUsemB);

		    print STDERR "SEMREL: " . scalar(@semrelA) . " " . scalar(@semrelB)."\n" if ($DEBUG > 3);
		    if (&compareArray(\@semrelA, \@semrelB) == 1) {
			if ($useRefTable) {
			    my @usynA = &selectUsyn($dbh,$idUsemA);
			    my @usynB = &selectUsyn($dbh,$idUsemB);

			    print STDERR "USYN: " . scalar(@usynA) . " " . scalar(@usynB)."\n"  if ($DEBUG > 3);
			    if (&compareArray(\@usynA, \@usynB) == 1) {
				if (! &isAlreadyInRedundantTable($dbh, $redundantUsem, $idUsemB, "idRedundant", $status)){
				    print $output "$idUsemB\t$idUsemA\n" if ($outputOnFiles ==1); ############ OUTPUT
				    if(&checkRedundantInTable ($dbh, $redundantUsem, $idUsemB, $idUsemA, $status) == 0) {
					&insertRedundantInTable($dbh, $redundantUsem, $idUsemB, $idUsemA, $status);
					$inserted++;
				    }
				}
			    } else {
				print STDERR "$idUsemB is NOT a duplicate of $idUsemA\n" if ($DEBUG > 2);
			    }
			} else {
			    #not use Usyn
			    if (! &isAlreadyInRedundantTable($dbh, $redundantUsem, $idUsemB, "idRedundant", $status)){
				print $output "$idUsemB\t$idUsemA\n" if ($outputOnFiles ==1) ; ############ OUTPUT
				if(&checkRedundantInTable ($dbh, $redundantUsem, $idUsemB, $idUsemA, $status) == 0) {
				    &insertRedundantInTable($dbh, $redundantUsem, $idUsemB, $idUsemA, $status);
				    $inserted++;
				}
			    }
			}
		    } else {
			print STDERR "SEMREL:  $idUsemB is NOT a duplicate of $idUsemA\n\n" if ($DEBUG > 3);
		    }
		} else {
		    print STDERR  "PREDICATE: $idUsemB is NOT a duplicate of $idUsemA\n\n" if ($DEBUG > 3);
		}
	    } else {
		print STDERR "TEMPLATES: $idUsemB is NOT a duplicate of $idUsemA\n\n" if ($DEBUG > 3);
	    }
	} else {
	    print STDERR "TRAITS: $idUsemB is NOT a duplicate of $idUsemA\n\n" if ($DEBUG > 3);
	}
    }
    $sth->finish;
    $dbh->disconnect;
    close($output) if ($outputOnFiles ==1);

    print STDERR "Rows inserted: $inserted\n";
}

sub findUsynCanditateRedundant () {

    my ($useComment, $useMus, $useExemple, $useRefTable) = @_;

    my $status = &bin2dec($useRefTable.$useExemple.$useMus.$useComment);
    my $refTable = "";
    if ($useRefTable) {
	$refTable = "usem";
    }


    if($outputOnFiles == 1) {
	my $filename = &outputFileName($useComment, $useDefinition, $onTable, $useMus, $useExemple, $refTable, $status);
	open( $output, '>', $filename ) or die("Unable to create/open $filename");
    }
    my $sqlString =
	"SELECT u.idUsyn, u.idUms, u2.idUsyn, u2.idUms ".
	"FROM usyns u, usyns u2 " .
	"WHERE " .
	"u.naming = u2.naming ".
	"and u.pos = u.pos ".
	"and COALESCE (u.description,'') = COALESCE (u2.description,'') " .
	"and COALESCE (u.descriptionL,'') = COALESCE (u2.descriptionL,'') " .
	"and COALESCE (u.framesetL,'') = COALESCE (u2.framesetL,'') ";
    if ($useMus) {
	$sqlString .= "and u.idUms = u2.idUms ";
    }
    if ($useExemple)  {
	$sqlString .= "and COALESCE (u.example,'') = COALESCE (u2.example,'') ";
    }
    if ($useComment)  {
	$sqlString .= "and COALESCE (u.comment,'') = COALESCE (u2.comment,'') ";
    }

    $sqlString .= "and u.idUsyn < u2.idUsyn";

    print STDERR "query: " . $sqlString . "\n" if ($DEBUG > 0);
    my $dbh = &getDBConnection();

    my $sth = $dbh->prepare($sqlString)
	or die "prepare statement failed: $dbh->errstr()";

    $sth->execute() or die "execution failed: $dbh->errstr()";
    my $inserted = 0;
    while (my ($idUsynA, $idUmsA, $idUsynB, $idUmsB) = $sth->fetchrow_array) {
	print STDERR "\$idUsynA=$idUsynA, \$idUmsA=$idUmsA, \$idUsynB=$idUsynB, \$idUmsB=$idUmsB\n" if ($DEBUG > 2);

	my $musEqual = ($idUmsA eq  $idUmsB);
	print STDERR "musEqual: ($musEqual), $idUmsA <=> $idUmsB\n" if ($DEBUG > 4);
	if ($useRefTable) {
	    my @semuA = &selectSemuByUsyn($dbh, $idUsynA);
	    my @semuB = &selectSemuByUsyn($dbh, $idUsynB);

	    #se i due vettori sono vuoti => si considerano come uguali
	    print STDERR "SEMU: " . scalar(@semuA) . " " . scalar(@semuB)."\n" if ($DEBUG > 2);
	    if ((scalar(@semuA) eq scalar(@semuB)) ){ #and (scalar(@semuA) > 0) ) {
		if ( &compareArray(\@semuA, \@semuB) == 1 || $useRefTable == 0) {
		    #SEMU Uguali o non controllate
		    if ((($useMus and $musEqual)) or (!$useMus)){
			#va controllato che idUsynB non sia già presente come duplicato
			#es. Se gia' presenti A dup B, C dup A => C dup B non va inserito

			if (! &isAlreadyInRedundantTable($dbh, $redundantUsyn, $idUsynB, "idRedundant",$status )){
			    print $output "$idUsynA\t$idUsynB\n" if ($outputOnFiles ==1);
			    if(&checkRedundantInTable ($dbh, $redundantUsyn,$idUsynB, $idUsynA, $status) == 0) {
				&insertRedundantInTable($dbh, $redundantUsyn, $idUsynB, $idUsynA, $status);
				$inserted++;
			    } else {
				print STDERR "triple $idUsynA, $idUsynB, $status already present\n" if ($DEBUG > 2);
			    }
			}
		    } else {
			print STDERR "$idUsynB is NOT a duplicate of $idUsynA\n" if ($DEBUG > 2);
		    }
		} else {
		    #SEMU differenti
		}
	    } else {
		#SEMU differenti in numero
	    }
	} else {
	    if ((($useMus and $musEqual)) or (!$useMus)){
		if (! &isAlreadyInRedundantTable($dbh,  $redundantUsyn, $idUsynB, "idRedundant")) {
		    print $output "$idUsynA\t$idUsynB\n" if ($outputOnFiles ==1);
		    if (&checkRedundantInTable($dbh, $redundantUsyn, $idUsynB, $idUsynA, $status) == 0) {
			&insertRedundantInTable($dbh, $redundantUsyn, $idUsynB, $idUsynA, $status);
			$inserted++;
		    } else {
			    print STDERR "$idUsynA, $idUsynB, $status already present\n" if ($DEBUG > 2);
		    }
		}
	    }
	}
    }
    $sth->finish;
    $dbh->disconnect;
    close($output) if ($outputOnFiles ==1);

    print STDERR "Rows inserted: $inserted\n";
}

### Check if that redundancy is found previously
sub checkRedundantInTable () {
    my ($dbh, $table, $idRedundant, $idRedundantOf, $type,$status) = @_;

    my $sth = $dbh->prepare("SELECT COUNT(*) AS cnt FROM " . $table . " WHERE idRedundant =  ? AND idRedundantOf = ? AND status = ?");
    $sth->execute($idRedundant, $idRedundantOf, $type) or die "execution failed: $dbh->errstr()"; 
    my $ref = $sth->fetchrow_hashref(); #only one row in resultset
    my $res = 0;
    if($ref) {
	$res = $ref->{cnt};
    }
    print STDERR "checkRedundantInTable (table=$table, idRedundant=$idRedundant, idRedundantOf=$idRedundantOf, status=$status): res=(" . $res.")\n" if ($DEBUG > 2);

    $sth->finish;

    return $res;
}

### insert the redundancy information found in the proper table
sub insertRedundantInTable () {

    my ($dbh, $table, $idRedundant, $idRedundantOf, $type) = @_;
    #INSERT into DuplicateUsem values ("USem01934maiale", "USem01934maiale", 5)
    my $sth = $dbh->prepare("INSERT INTO " .$table. " VALUES (NULL,?,?,?)");
    print STDERR ".";
#    eval {$sth->execute($idRedundant, $idRedundantOf, $type)};  warn $@ if $@;
    $sth->execute($idRedundant, $idRedundantOf, $type) or print STDERR "*** Error: " . $dbh->errstr;

    $sth->finish;
    $dbh->commit;# or die $dbh->errstr;

}

### It compares two array
sub compareArray () {
    my ($A, $B) = @_;
    my $equals;
    my @arrayA = @{$A};
    my @arrayB = @{$B};
    print STDERR "COMPARE : " . @arrayA . " " . @arrayB."\n" if($DEBUG > 3);
    if (@arrayA != @arrayB) {
	print STDERR "not equal in size => B is not duplicate of A\n" if($DEBUG > 3);
	$equals = 0;
    } else {
	if (@arrayA == 0) {
	    print STDERR "COMPARE : " . @arrayA . " " . @arrayB. " A and B don't have any elements\n" if($DEBUG > 3);
	}
	$equals = 1;
	for my $i (0 .. $#arrayA) {
	    # Ideally, check for undef/value comparison here as< well
	    print STDERR "compareArray: " . $i . " " . $#{ $arrayA[$i]}. "\n" if($DEBUG > 4);

	    for my $j (0 .. $#{$arrayA[$i]}) {
		print STDERR "compareArray " . $i . ", size=". $#{$arrayA[$i]}.": (" . $arrayA[$i][$j] . ") <=> (" . $arrayB[$i][$j] .")\n" if($DEBUG > 4);
		print STDERR "compareArray " . $i . ", j=" . $j . " ". $arrayA[$i][$j]. " " .$arrayB[$i][$j] . "\n" if($DEBUG > 4);
		if (lc($arrayA[$i][$j]) ne lc($arrayB[$i][$j])) { # use "ne" if elements are strings, not numbers
		    # Or you can use generic sub comparing 2 values
		    print STDERR "compareArray " . lc($arrayA[$i][$j]) . " NOT EQUALS " . lc($arrayB[$i][$j]) . "\n" if($DEBUG > 3);
		    $equals = 0;
		    last;
		}
	    }
	}
  }
    print STDERR "compareArray: $equals\n" if($DEBUG > 2);
    return $equals;
}

### Retrive id for the usem linked with a specified Usyn identified by idUsyn
sub selectSemuByUsyn () {
    my ($dbh, $idUsyn) = @_;

    my $query = "SELECT t.idUsem FROM usynusem t WHERE t.idUsyn = ?";

    my $sth = $dbh->prepare($query)
	or die "prepare statement failed: $dbh->errstr()";

    $sth->execute($idUsyn) or die "execution failed: $dbh->errstr()";

    my @res;
    while (my $ref = $sth->fetchrow_arrayref()) {
	push(@res,$ref);

    }
    return @res;
}

### Retrieve the value for @columns (list of column) about a row identified by idUsem in the table $table (that must have idUsem column!)
sub selectAllFromTableWhereIDUsem() {
    my ($dbh, $table, $idUsem, @columns) = @_;

    my $query = "SELECT * FROM " . $table . " t WHERE t.idUsem = ?";
    if(@columns) {
	$query .= " order by";
	foreach my $col (@columns) {
	    $query .= " ".$col.",";
	}
	chop($query);
    }
    print STDERR "QUERY: " . $query . "\n" if ($DEBUG > 2);
    my $sth = $dbh->prepare($query)
	or die "prepare statement failed: $dbh->errstr()";
    $sth->execute($idUsem) or die "execution failed: $dbh->errstr()";

    my @res;

    while (my $ref = $sth->fetchrow_hashref()) {
	my @row;
	foreach my $col (@columns) {
	    if ( exists $ref->{$col}) {
		print STDERR "selectAllFromTableWhereIDUsem:". $idUsem ." => ". $ref->{$col}."\n" if($DEBUG > 2);
		push(@row,$ref->{$col});
	    } else {
		die "No column " . $col . " in table " . $table ;
	    }
	}
	push (@res, \@row);
    }

    $sth->finish;
    return @res;
}

sub selectTraits () {
    my ($dbh, $idUsem) = @_;
    my @res = &selectAllFromTableWhereIDUsem ($dbh, "usemtraits", $idUsem, qw (idTrait));
#    print @res."\n";

    return @res;
}

sub selectTemplates () {
    my ($dbh, $idUsem) = @_;
    my @res = &selectAllFromTableWhereIDUsem ($dbh, "usemtemplates", $idUsem, qw (idTemplate));
#    print @res."\n";

    return @res;
}

sub selectPredicate () {
    my ($dbh, $idUsem) = @_;
    my @res = &selectAllFromTableWhereIDUsem ($dbh, "usempredicate", $idUsem, qw (idPredicat));
#    print @res."\n";

    return @res;
}
    
sub selectSemRel () {
    my ($dbh, $idUsem) = @_;
    my @res = &selectAllFromTableWhereIDUsem ($dbh, "usemrel", $idUsem, qw (idRSem idUsemTarget));
#    print @res."\n";

    return @res;
}

sub selectUsyn () {
    my ($dbh, $idUsem) = @_;
    my $sth =  $dbh->prepare("SELECT  idUsyn ".
			     "FROM usynusem u, usem u2 ".
			     "WHERE LOWER(u.idUsem) = LOWER(u2.idUsem) AND LOWER(u2.idUsem) = LOWER('" . $idUsem."')")
	or die "prepare statement failed: $dbh->errstr()";

    $sth->execute() or die "execution failed: $dbh->errstr()";

    my @res;
    #    print @res."\n";
    while (my $ref = $sth->fetchrow_hashref()) {
	my @row;
	my @columns = qw (idUsyn);
	foreach my $col (@columns) {
	    if ( exists $ref->{$col}) {
		print STDERR "selectUsyn:". $idUsem ." => ". $ref->{$col}."\n" if($DEBUG > 2);
		push(@row,$ref->{$col});
	    } else {
		die "No column " . $col . " in table USyns";
	    }
	}
	push (@res, \@row);
    }

    return @res;
}


sub outputFileName () {

    my ($useComment, $useDefinition, $onTable, $useMus,$useExemple, $refTable, $status) = @_;
    
    my $filename = "redundant_";
    if ($useComment) {
	$filename .= "commentYes_";
    } else {
	$filename .= "commentNo_";
    }
    if ($onTable eq "usem") {
	if ($useDefinition) {
	    $filename .= "definitionYes_";
	} else {
	    $filename .= "definitionNo_";
	}
    } else {
	if ($useMus) {
	    $filename .= "musYes_";
	} else {
	    $filename .= "musNo_";
	}
    }
    if ($useExemple) {
	$filename .= "exempleYes_";
    } else {
	$filename .= "exempleNo_";
    }
    if ($refTable eq "usem") {
	$filename .= "usemYes";
    } elsif ($refTable eq "usyn") {
	$filename .= "usynYes";
    } else {
	if ($onTable eq "usem") {
	    $filename .= "usynNo";
	} else {
	    $filename .= "usemNo";
	}
    }
    if ($onTable eq "usem") {
	$filename = "usem_" . $filename;
    } else {
	$filename = "usyn_" . $filename;
    }

    $filename .= "_". $status . ".csv";
     print STDERR "filename ". $filename . "\n";

    return $filename;
}


sub usage() {

    print STDERR "Usage: perl $0 -a <TABLENAME> -c -d -e -o <OUTPUTFILE> -x <DEBUGLEVEL> -s -t <TABLENAME> -m -r -h\n";
    print STDERR "\tOptions:\n\t-a [usem|usyn]: automatic discovery for all kind of redundancy in the specified table (all other options except -s and -x are ignored)\n\t-c : use comment field\n\t-d : use definition field [only -t usem]\n\t-e : use example filed\n\t-s : clean table specified with -t option\n\t-t [usem|usyn] : the table on which operate\n";
    print STDERR "\t-x INT : debug level [0 (no debug) to 5 (max debug)]\n\t-m : use mus table [only -t usyn]\n";
    print STDERR "\t-r : use ref table [usem when -t usyn and usyn when -t usem ]\n\t-o : resuls in separated output files\n\t-h this help\n"
}
