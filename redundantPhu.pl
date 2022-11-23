#!/usr/bin/perl
###
### @author Simone Marchi <simone.marchi(at)ilc.cnr.it>
###
use strict;
#use warnings;
use v5.10; # for say() function
use Getopt::Std;
use DBI;
#use Switch;
use Data::Dumper;
use Config::Simple;

my $cfg = new Config::Simple('app.cfg');

# MySQL database configuration
my $dsn = $cfg->param('mysql.dsn');
my $username = $cfg->param('mysql.username');
my $password = $cfg->param('mysql.password');

my $redundantPhuTableName = $cfg->param('mysql.redundantphu');

my $DEBUG = 0;

# declare the perl command line flags/options we want to allow
my %options=();
getopts("hdx:", \%options);

if (defined $options{h}) {
    &usage();
    exit;
}

if (defined $options{d}) {
    &dropCreateTable($redundantPhuTableName);
    exit;
}

if (defined $options{x}) {
    $DEBUG = $options{x};
}

&calculateRedundantPhu();


sub getDBConnection () {

    # connect to MySQL database
    my %attr = ( AutoCommit=>0,
		 PrintError=>0,  # turn off error reporting via warn()
		 RaiseError=>1);   # turn on error reporting via die()

    my $dbhandler = DBI->connect($dsn,$username,$password, \%attr) or die;

    return $dbhandler;

}

sub deleteFromTable() {
    my ($table) = @_; #usyns o usem

    print STDERR "cleanDB(): Delete from $table\n";# if($DEBUG > 0);
    my $dbh = getDBConnection();
    my $stmt = $dbh->prepare("DELETE FROM " . $table);
    $stmt->execute() or die;
    $stmt->finish;
    $dbh->commit or die $dbh->errstr;
    $dbh->disconnect;
}

sub dropCreateTable() {
    my ($table) = @_;

    my $create = "CREATE TABLE " . $table ." ( \ 
	 `id` int NOT NULL AUTO_INCREMENT,  \ 
	 `idRedundant` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL, \ 
	 `idRedundantOf` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL, \ 
	 `status` int DEFAULT NULL, \ 
	 PRIMARY KEY (`id`), \ 
	 UNIQUE KEY `RedundantPHU_UN` (`idRedundant`,`idRedundantOf`), \ 
	 KEY `RedundantPHU_FK_1` (`idRedundantOf`), \ 
	 CONSTRAINT `RedundantPHU_FK` FOREIGN KEY (`idRedundant`) REFERENCES `phu` (`idPhu`), \ 
	 CONSTRAINT `RedundantPHU_FK_1` FOREIGN KEY (`idRedundantOf`) REFERENCES `phu` (`idPhu`) \ 
	) ENGINE=InnoDB AUTO_INCREMENT=186 DEFAULT CHARSET=utf8mb3; \ ";

    my $drop = "Drop Table IF EXISTS " . $redundantPhuTableName;

    my $dbh = getDBConnection();

    my $stmt = $dbh->prepare($drop);
    $stmt->execute() or die;
    $stmt->finish;

    $stmt = $dbh->prepare($create);
    $stmt->execute() or die;
    $stmt->finish;

    $dbh->commit or die $dbh->errstr;
    $dbh->disconnect;
}


sub calculateRedundantPhu () {

    my $candidateRedudant =
	"select p.naming , p.phono, COUNT(*) as c \
		from phu p \
		group by p.naming , p.phono \
		HAVING (c>=2)";

    my $phuWithSameNamingAndPhono =
	"select idPhu \
		from phu p \
		where naming = ? \
		and phono = ? \
		Order By idPhu";

    my $dbh = &getDBConnection();

    my $sth = $dbh->prepare($candidateRedudant)
	or die "prepare statement failed: $dbh->errstr()";

    $sth->execute() or die "execution failed: $dbh->errstr()";

    my $inserted = 0;

    #for each candidate redundant
    while (my ($naming, $phono, $cnt) = $sth->fetchrow_array) {

	my $sth2 = $dbh->prepare($phuWithSameNamingAndPhono)
	    or die "prepare statement failed: $dbh->errstr()";

	$sth2->execute($naming, $phono) or die "execution failed: $dbh->errstr()";
	#to fetch just the first column of every row:
	my $tbl_ary_ref = $sth2->fetchall_arrayref;

	for my $i (0 .. @{$tbl_ary_ref} - 1) {
	    for my $j ($i .. @{$tbl_ary_ref} - 1) {
		if($i != $j) {
		    my $phuA = ${$tbl_ary_ref}[$i][0];
		    my $phuB = ${$tbl_ary_ref}[$j][0];
		    my $listOfMusPhuA = &getMusPhuOfPhu($phuA,$dbh);
		    my $listOfMusPhuB = &getMusPhuOfPhu($phuB,$dbh);
		    print STDERR "\nphuA: $phuA " if $DEBUG > 1;
		    print STDERR "vs phuB: $phuB\n" if $DEBUG > 1;
		    my $type = &calculateTypeOfRedudancy($listOfMusPhuA,$listOfMusPhuB);
		    if ($type == -3){
			print STDERR "INVERTED $phuA\t$phuB\t$type\n" if $DEBUG > 1;
			&insertIntoTable($dbh,$redundantPhuTableName,$phuA,$phuB,3);
			$inserted++;
		    } else {
			print STDERR "$phuB\t$phuA\t$type\n" if $DEBUG > 1;
			&insertIntoTable($dbh,$redundantPhuTableName,$phuB,$phuA,$type);
			$inserted++;
		    }
		}
	    }
	}
	$sth2->finish();
    }
    print STDERR "Rows inserted: $inserted\n";
    $sth->finish;
    $dbh->disconnect;
}

sub calculateTypeOfRedudancy {
    my ($listOfMusPhuA,$listOfMusPhuB) = @_;

    my $ret = 0;

    print STDERR "calculateTypeOfRedudancy: " . ref($listOfMusPhuA). ", " .ref($listOfMusPhuB)." \n" if $DEBUG > 1;

    my $lenA = @{$listOfMusPhuA};
    my $lenB = @{$listOfMusPhuB};

    print STDERR "\tMUSPHU A: ${$listOfMusPhuA}[0][0] ${$listOfMusPhuA}[0][1] ${$listOfMusPhuA}[0][2] lenA: $lenA\n" if $DEBUG > 2;
    print STDERR "\tMUSPHU B: ${$listOfMusPhuB}[0][0] ${$listOfMusPhuB}[0][1] ${$listOfMusPhuB}[0][2] lenB: $lenB\n" if $DEBUG > 2;

    if ($lenA == 0) {
	#	print STDERR "No mus of Reference for A\n";
	$ret = -3;
    } elsif ($lenB == 0) {
	#	print STDERR "No mus of Reference for B: $listOfMusPhuB\n";
	$ret = 3;
    } elsif (&haveSameMusOfReference($listOfMusPhuA,$listOfMusPhuB) == 1) {
	if (&haveSameMorphFeat($listOfMusPhuA,$listOfMusPhuB) == 1) {
	    $ret = 1;
	} else {
	    $ret = 2;
	}
    } else {
	$ret = 4;
    }

    print STDERR "\tType of redundacy is $ret\n" if $DEBUG > 1;

    return $ret;
}

sub haveSameMorphFeat () {
    my ($listOfMusA,$listOfMusB) = @_;

    return &compareMusOfReference($listOfMusA,$listOfMusB, 1);
}

sub haveSameMusOfReference () {
    my ($listOfMusA,$listOfMusB) = @_;

    return &compareMusOfReference($listOfMusA,$listOfMusB, 0);
}

sub compareMusOfReference () {
    my ($listOfMusA,$listOfMusB, $compareMorphFeat) = @_;

    my $ret = 0;
    for my $i (0 .. @{$listOfMusA} - 1) {
	for my $j (0 .. @{$listOfMusB} - 1) {
	    if (${$listOfMusA}[$i][0] eq ${$listOfMusB}[$j][0]) {
		if($compareMorphFeat == 1) {
		    if (${$listOfMusA}[$i][2] eq ${$listOfMusB}[$j][2]) {
			$ret = 1;
		    }
		} else {
		    $ret = 1;
		}
	    }
	}
    }
    return $ret;
}

sub getMusPhuOfPhu() {
    my ($phu,$dbh) = @_;
    
    my $musByPhu = "select idMus, pos, morphFeat from musphu where idPhu=?";

    my $sth = $dbh->prepare($musByPhu);
    $sth->bind_param (1, "$phu");

    $sth->execute() or die "execution failed: $dbh->errstr()";
    my $res = $sth->fetchall_arrayref;
    $sth->finish();

    return $res;
}

### insert the redundancy information found in the proper table
sub insertIntoTable () {
    my ($dbh, $table, $idRedundant, $idRedundantOf, $status ) = @_;

    my $sth = $dbh->prepare("INSERT INTO " .$table. " VALUES (NULL,?,?,?)");

    print STDERR "$idRedundant will be marked as redundat of $idRedundantOf with status $status\n" if $DEBUG > 0;
    print STDERR "INSERT INTO " .$table. " VALUES ($idRedundant, $idRedundantOf, int($status))\n" if $DEBUG > 2;
    $sth->execute($idRedundant, $idRedundantOf, int($status)) or print STDERR "*** Error: " . $dbh->errstr;
    print STDERR ".";
    $sth->finish;
    $dbh->commit or die $dbh->errstr;

}


sub usage() {

    print STDERR "Usage: perl $0 -x <DEBUGLEVEL> | -d \n";
    print STDERR "\tOptions:\n\t-x INT : debug level [0 (no debug, default) to 5 (max debug)]";
    print STDERR "\n\t-d : drop and create table only";
    print STDERR "\n\t-h this help\n"
}
