#!/usr/bin/perl -w
# conkyrss - fetch rss and 
# format for display by conky
# Harry Stone 11/14/2013
#========================================
use XML::Feed;
use LWP::Simple;
use POSIX qw(strftime);
#========================================
# config
$width = 100; # set the width of the conky window here
$outputrecords = 3; # qty of RSS entries to output on each run
$user = "/home/user"; # your home directory
#========================================

&Main();

#----------#
sub Main {
    $filestatus = &CheckRSS();
    if ($filestatus eq "true") {
        &Output();
    } else {
        $linksstatus = &CheckLinksRun();
        if ($linksstatus eq "true") {
            &FetchRSS();
        } else {
            &MakeLinksRun();
        }    
    }
}
#----------#
sub Output {
    $rssdata = "$user/.rss/data.rss";
    open(DATA, "<", "$rssdata");
    $data = do { local $/; <DATA> };
    close(DATA);
    @records = split(/-----/, $data);
    $recordcount = 1;
    while ($recordcount le $outputrecords) {
	    $rssentry = shift(@records);
	    @rsplit = split(/\|/, $rssentry);
	    $channel = $rsplit[0];
	    $fetched = $rsplit[1];
	    $title = $rsplit[2];
	    $body = $rsplit[3];
	    print "$channel  -  $fetched\n";
	    print "$title\n";
	    print "$body\n";
	    print "\n";
	    $recordcount++;
    }
    # write remainder back to file; if empty then delete file
    if (@records) {
        open(DATAOUT, ">", "$rssdata");
        while(@records) {
            $dout = shift(@records);
            print DATAOUT "$dout"."-----";
        }   
    close(DATAOUT);
    } else {
	system("/bin/rm -f $rssdata");
    }
exit;
}
#----------#
sub CheckRSS {
    $rssdata = "$user/.rss/data.rss";
    if (-e -s "$rssdata") {
        return "true";
    } else {
        return "false";
    }
}
#----------#
sub CheckLinksRun {    
    $linksrun = "$user/.rss/linksrun";
     if (-e -s "$linksrun") {
        return "true";
    } else {
        return "false";
    }
}
#----------#
sub MakeLinksRun {
    system("/usr/bin/cp $user/.rss/rsslinks $user/.rss/linksrun");
    &Main;
}
#----------#
sub FetchRSS {
    $linksrun = "$user/.rss/linksrun";
    open(LINKS, "<", "$linksrun");
    while (<LINKS>) {
	    push(@links, $_);
    }
    close(LINKS);
	$outfile = glob('~/.rss/data.rss');
	open(OUT, ">", "$outfile");
	$url = shift(@links);
	my $rss = get $url or die "Couldn't get $url: $!";
	my $feed = XML::Feed->parse(\$rss);
	$channel = $feed->title;
	$date = strftime "%D %r", localtime;

	foreach ($feed->entries) {
		$title = $_->title;
		$title =~ s/[^\x20-\xFE]//sg;
		chomp($title);
		$body = $_->content->body;
		$body =~ s/<.+?>//sg;
		$body =~ s/[^\x20-\xFE]//sg;
		chomp($body);
		print OUT "$channel"."|"."Fetched: $date"."|"."$title"."|";
        
        @body = split(/ /, $body);
        $bodyout = "";
        while (@body) {
            $word = shift(@body);
            if (length($bodyout) + length($word) <= $width) {
                $bodyout = "$bodyout"." $word"
            } else {
                print OUT "$bodyout\n";
                $bodyout = '';
                $bodyout = $word;
            }
        }
        # '-----' is our quick and dirty record delimiter
        print OUT "$bodyout"."|"."-----\n";
	}
    close(OUT);
    open(LINKS, ">", "$user/.rss/linksrun");
    #chomp(@links);
    print LINKS "@links";
    close(LINKS)
    &Main;
}

