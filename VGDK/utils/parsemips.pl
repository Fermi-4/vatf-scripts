use strict 'vars';
use Diagnostics;
use Socket;
use Sys::Hostname;

my (@tasks) = ("end",       #  0
               "txrx",      #  1   chdep
               "rx",        #  2   chdep
               "tx",        #  3   chdep
               "tdurx",     #  4   chdep
               "vcurx",     #  5   chdep
               "ecu",       #  6   chdep
               "tdutx",     #  7   chdep
               "vcutx",     #  8   chdep
               "pvptx",     #  9   chdep
               "rcutx",     #  10   chdep
               "neutx",     #  11  chdep
               "ndutx",     #  12  chdep
               "pvprx",     #  13  chdep
               "rcurx",     #  14   chdep
               "neurx",     #  15   chdep
               "ndurx",     #  16   chdep
               "piutx",     #  17   chdep
               "piurx",     #  18   chdep
               "vpputx",    # 19   chdep 
               "vppurx",    # 20   chdep 
               "vtkDecode", # 21   chindep 
               "vtkOverlay",# 22   chindep 
               "vtkEncode", # 23   chindep 
               "cache_inv", # 24   chindep 
               "cache_inv_wb", # 25   chindep 
               "tsu_tx",       # 26   chindep 
               "reserved_ch9",     # 27   chindep 
               "reserved_ch10",    # 28   chindep 
               "haltx",    #  29  chindep
               "mcbsp1",   #  30  chindep clock
               "mcbsp2",   # 31   chindep
               "mcbsp3",   # 32   chindep
               "utrx",     # 33   chindep ch=cells
               "utrxpoll", # 34   chindep ch=cells
               "uttx",     # 35   chindep
               "dsig",     # 36   chindep
               "ecuma",    # 37   chindep
               "prd",      # 38   chindep
               "txrxswi",  # 39   chindep
               "main",     # 40   chindep
               "mipswaster",   # 41   chindep
               "tdmedmasort",  # 42   chindep
               "gmaccomm",     # 43   chindep
               "gmactx",       # 44   chindep
               "gmacrx",       # 45   chindep
               "gmacpoll",     # 46   chindep
               "dpBadPred",    # 47   chindep
               "dpBusyDDR",    # 48   chindep
               "dpBusyCtl",    # 49   chindep
               "dpPred",       # 50   chindep
               "dpReloc",      # 51   chindep
               "dpBusyDDR_MP", # 52   chindep
               "ecumaCtrl",    # 53   chindep
               "profMsg",    # 54   chindep 
               "tecEng",    # 55   chindep 
               "reserved3",    # 56   chindep 
               "reserved4",    # 57   chindep 
               "reserved5",    # 58   chindep 
               "reserved6",    # 59   chindep 
               "idle");        # 60   chindep
my ($firstchtask, $lastchtask, $maxch, $firstchascount, $lastchascount, $clock_task, $profSendMsgTask) = (  
1,   # first per channel task
  26,   # last per channel task
  100, # max number of channels
  33,  # first task using channels for count
  34,  # last task using channels for count
  30,  # task ID to treat as clock
 54); # Task ID for profiling send message overhead (janus only)

my (@taskarray, @data);
my ($NOPUSHPOP, $PUSH, $POP) = (0,1,2);
my ($error) = (1);
my (@row, $clock, $startts, @rows, $prev_count, $bychan_lines, $outputbase);

if ($ARGV[0] eq "-h64xbe") {
  if ($#ARGV == 2) {
    load_h64xbe(\@data, $ARGV[1]);
    process_dump(\@data, $ARGV[2]);
    $error = 0;
  }
} elsif ($ARGV[0] eq "-h64xle") {
  if ($#ARGV == 2) {
    load_h64xle(\@data, $ARGV[1]);
    process_dump(\@data, $ARGV[2]);
    $error = 0;
  }
} elsif ($ARGV[0] eq "-b64xle") {
  if ($#ARGV == 2) {
    load_b64xle(\@data, $ARGV[1]);
    process_dump(\@data, $ARGV[2]);
    $error = 0;
  }
} elsif ($ARGV[0] eq "-b") {
  if ($#ARGV == 2) {
    load_hostbuf(\@data, $ARGV[1]);
    process_dump(\@data, $ARGV[2]);
    $error = 0;
  }
} elsif ($ARGV[0] eq "-lddr") {
  if ($#ARGV == 1) {
    while(1) {
      $outputbase = listenport(\@data, $ARGV[1]);
      process_dump(\@data, $outputbase);
    }
  }
}


if ($error) {
   print "Syntax: C64X .dat (big endian)    : $0 -h64xbe input.dat outputbase\n";
   print "Syntax: C64X .dat (little endian) : $0 -h64xle input.dat outputbase\n";
   print "Syntax: C64X .dat (binary  little endian) : $0 -b64xle input.dat outputbase\n";
   print "        C64X/DDR port listener    : $0 -lddr listen_port\n";
   print "        host binary buffer        : $0 -b input.bin outputbase\n";
   exit(1);
}


sub process_dump {
  my ($dataref, $basename) = @_;
  my ($i);

  @row = ();
  @rows = ();
  $bychan_lines= 0;
  output_hdr();

  # reset total cycles
  $row[calculate_row_idx($lastchtask, $maxch - 1) + 1] = 0;
  $startts = $clock = 0;
  for ($i=0;$i<=$#$dataref;$i+=2) {
    parse_trace($$dataref[$i], $$dataref[$i+1]);
    if (($i % (20*1024)) == 0) {
      $| = 1;
      print "Processed ", $i/2, " records\r";
      $| = 0;
    }
  }
  @{$dataref} = ();
  print "Processed ", $i/2, " records\n";
  output_row();
  output_matrix($basename);
}

sub parse_trace {
  my (@args) = (@_);
  my ($task, $poptask, $cid, $count, $idx, $pushpop, $delta);
  $task    = ($args[1] >> 10) & 0x3f;
  $pushpop = ($args[1] >> 8) & 0x3;
  $cid     = ($args[1] & 0xff);
  $count   = $args[0];

  do {
    $delta = ($count - $prev_count);
    if ($delta < -(64*1024*4)) {
      $delta &= 0xffffff;
    }
    # Fix double read race in DSP code
    if ($delta < 0) {
      $count += 65536;
    }
#    print "Delta = $delta\n";
  } while ($delta < 0);

#  $delta = ($count - $prev_count) & 0xffffff;
  $prev_count = $count;

  if ($#taskarray >= $[) {
    ${$taskarray[$#taskarray]}[2] += $delta;
  }
  if ($pushpop == $PUSH) {
    push @taskarray, [$task, $cid, 0];
    return;
  }

# pop/calculate
  ($poptask, $cid, $count) = @{pop @taskarray};
  $task = $poptask if ($task == 0);

  if ($task == $clock_task) { 
    $clock++;
  }
  if ($tasks[$task] eq "") {
    print "task=$task $tasks[$task],$cid,$count\n";
    print sprintf "0x%08x  0x%08x\n", $args[0], $args[1];
  }

  $idx = calculate_row_idx ($task, $cid);
  if (($task >= $firstchtask) && ($task <= $lastchtask)) {
    if (defined $row[$idx]) {
      output_row();
    } 
    $row[$idx] = $count;
  } else {
    if (! defined $row[$idx]) {
      $row[$idx] = 1;
      $row[$idx+1] = $count;
      if (($task >= $firstchascount) && ($task <= $lastchascount)) {
        $row[$idx+2] = "$cid";
      }
    } else {
      $row[$idx]++;
      $row[$idx+1] += $count;
      if (($task >= $firstchascount) && ($task <= $lastchascount)) {
        $row[$idx+2] .= ";$cid";
      }
    }
  }
  # total cycles in row
  $row[$#row] += $count;
}

sub output_row {
  push @rows, [$startts, @row];
  $bychan_lines ++;
  @row = ();
  $startts = $clock;
  # reset total cycles
  $row[calculate_row_idx($lastchtask, $maxch - 1) + 1] = 0;
}

sub output_hdr {
  my ($i,$j);

  @row = "timestamp";
  for ($i=$lastchtask + 1;$i <= $#tasks; $i++) {
    push @row, "${tasks[$i]}_count","${tasks[$i]}";
    if (($i >= $firstchascount) && ($i <= $lastchascount)) {
      push @row, "${tasks[$i]}_nproc";
    }
  }
  for ($i=0;$i<$maxch;$i++) {
    for ($j=$firstchtask;$j<=$lastchtask;$j++) {
      push @row, "${tasks[$j]}_ch$i";
    }
  }

  push @row, "totalcount";
  @rows = ([@row]);
  @row = ();
}

sub calculate_row_idx {
  my ($task, $cid) = @_;
  my ($idx);
  if (($task >= $firstchtask) && ($task <= $lastchtask)) {
    $idx = 2 * ($#tasks - $lastchtask) + 
           ($lastchascount - $firstchascount + 1) + 
           (($lastchtask - $firstchtask + 1) * $cid) + ($task - 1);
  } else {
    $idx = 2 * ($task - ($lastchtask + 1));
    if ($task > $firstchascount) {
      if ($task <= $lastchascount) {
        $idx += ($task - $firstchascount);
      } else {
        $idx += ($lastchascount - $firstchascount + 1);
      }
    }
  }

  return $idx;
}

sub output_matrix {
  my ($outputbase) = @_;
  my ($i,$j, $k, $cols, $newcols, $statrow);
  my (@row);
  my ($CNTVALID, $CNTBLANK, $SUM, $MIN, $AVG, $MAX) = (1,2,3,4,5,6);
  $cols = $#{$rows[0]} + 1;
  $statrow = $#rows + 1;

  print "Current cols: $cols\n";
  for ($i=0;$i<$cols;$i++) {
    $row[$i] = 0;
    ${$rows[$statrow + $CNTVALID]}[$i] = 0;
    ${$rows[$statrow + $CNTBLANK]}[$i] = 0;
    ${$rows[$statrow + $SUM]}[$i] = 0;
    ${$rows[$statrow + $MAX]}[$i] = 0;
    ${$rows[$statrow + $MIN]}[$i] = 0x7fffffff;
  }

  # Calc stats and identify inactive columns;
  # Ignore first and last row
  for ($i=2; $i<$statrow-1; $i++) {
    for ($j=0; $j<=$#{$rows[$i]}; $j++) {
      if (defined ${$rows[$i]}[$j]) {
        $row[$j] ++;
        ${$rows[$statrow + $CNTVALID]}[$j]++;
        ${$rows[$statrow + $SUM]}[$j] += ${$rows[$i]}[$j];
        ${$rows[$statrow + $MAX]}[$j] = ${$rows[$i]}[$j] if (${$rows[$statrow + $MAX]}[$j] < ${$rows[$i]}[$j]);
        ${$rows[$statrow + $MIN]}[$j] = ${$rows[$i]}[$j] if (${$rows[$statrow + $MIN]}[$j] > ${$rows[$i]}[$j]);
      } else {
        ${$rows[$statrow + $CNTBLANK]}[$j] ++;
      }
    }
  }

  # Find active columns and compute averages for them.
  $newcols = 0;
  for ($i=0;$i<$cols;$i++) {
    if ($row[$i]) {
      $newcols ++;
      ${$rows[$statrow + $AVG]}[$i] = int ((${$rows[$statrow + $SUM]}[$i] / ${$rows[$statrow + $CNTVALID]}[$i]) + 0.5);
    }
  }
  print "Reformatted cols: $newcols\n";
  if ($cols != $newcols) {
    for ($i=0; $i<=$#rows; $i++) {
      for ($j=0, $k=0; $j<=$#{$rows[$i]}; $j++) {
        if ($row[$j]) {
          ${$rows[$i]}[$k++] = ${$rows[$i]}[$j];
        }
      }
      $#{$rows[$i]} = $newcols - 1;
    }
  }
  print "Write output\n";
  open BYCHAN, ">${outputbase}.csv" or die "Can't open output file $(outputbase).csv\n";
  for ($i=0; $i<=$#rows; $i++) {
    print BYCHAN join (',', (@{$rows[$i]})), "\n";
  }
  close BYCHAN;

  if ($newcols > 250) {
    my($startcol, $stopcol, $fname) = (0, 249);
    while ($startcol < $newcols) {
      $fname = sprintf("${outputbase}_%04d_%04d.csv", $startcol, $stopcol);
      print "Output $fname\n";
      open PARTIAL, ">$fname" or die "Can't open $fname for output\n";
      for ($i=0; $i<=$#rows; $i++) {
        print PARTIAL join (',', (@{$rows[$i]})[$startcol..$stopcol]), "\n";
      }
      close PARTIAL;
      $startcol = $stopcol + 1;
      $stopcol = $startcol + 249;
      $stopcol = $newcols - 1 if ($stopcol >= $newcols);
    }
  }
}

sub load_h64xle {
  my ($dataref, $fname) = @_;
  my ($val1, $val2, $val3, $word1, $word2, $word3);
  my ($total_words) = 0;
  @$dataref = ();
  open INPUT, $fname or die "Can't open input $fname\n";
  # toss header
  <INPUT>;

  while(!eof(INPUT)) {
    $word1 = hex <INPUT>;
    last if (eof(INPUT));
    $word2 = hex <INPUT>;

    $val1 = $word1 & 0xffff;
    $val2 = $word1 >> 16;
    $val3 = $word2 & 0xffff;
    push @$dataref, ($val1 << 16) | $val2, $val3;
    $total_words += 3;

    last if (eof(INPUT));
    $word3 = hex <INPUT>;

    $val1 = $word2 >> 16;
    $val2 = $word3 & 0xffff;
    $val3 = $word3 >> 16;
    push @$dataref, ($val1 << 16) | $val2, $val3;
    $total_words += 3;

    if ( ($total_words % (64*1024)) <4) {
      $| = 1;
      print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\r";
      $| = 0;
    }
  }
  print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\n";
  close INPUT;
}

sub readbin32 {
  my ($littleEndian) = @_;
  my (@chrs, $retVal);
  @chrs = (ord getc(INPUT),
           ord getc(INPUT),
           ord getc(INPUT),
           ord getc(INPUT));
  if (! $littleEndian) {
    $retVal = ($chrs[0] << 24) |
              ($chrs[1] << 16) |
              ($chrs[2] <<  8) |
              ($chrs[3]      );
  } else {
    $retVal = ($chrs[3] << 24) |
              ($chrs[2] << 16) |
              ($chrs[1] <<  8) |
              ($chrs[0]      );
  }
  return $retVal;
}
sub load_b64xle {
  my ($dataref, $fname) = @_;
  my ($val1, $val2, $val3, $word1, $word2, $word3);
  my ($total_words) = 0;
  @$dataref = ();
  open INPUT, $fname or die "Can't open input $fname\n";
  binmode (INPUT);
  my $littleEndian = 1;

  while(!eof(INPUT)) {
    $word1 = readbin32 (1);
    last if (eof(INPUT));
    $word2 = readbin32 (1);

    $val1 = $word1 & 0xffff;
    $val2 = $word1 >> 16;
    $val3 = $word2 & 0xffff;
    push @$dataref, ($val1 << 16) | $val2, $val3;
    $total_words += 3;

    last if (eof(INPUT));
    $word3 = readbin32 (1);

    $val1 = $word2 >> 16;
    $val2 = $word3 & 0xffff;
    $val3 = $word3 >> 16;
    push @$dataref, ($val1 << 16) | $val2, $val3;
    $total_words += 3;

    if ( ($total_words % (64*1024)) <4) {
      $| = 1;
      print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\r";
      $| = 0;
    }
  }
  print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\n";
  close INPUT;
}

sub load_h64xbe {
  my ($dataref, $fname) = @_;
  my ($val1, $val2, $val3, $word1, $word2, $word3);
  my ($total_words) = 0;
  @$dataref = ();
  open INPUT, $fname or die "Can't open input $fname\n";
  # toss header
  <INPUT>;

  while(!eof(INPUT)) {
    $word1 = hex <INPUT>;
    last if (eof(INPUT));
    $word2 = hex <INPUT>;

    $val1 = $word1 >> 16;
    $val2 = $word1 & 0xffff;
    $val3 = $word2 >> 16;
    push @$dataref, ($val1 << 16) | $val2, $val3;
    $total_words += 3;

    last if (eof(INPUT));
    $word3 = hex <INPUT>;

    $val1 = $word2 & 0xffff;
    $val2 = $word3 >> 16;
    $val3 = $word3 & 0xffff;
    push @$dataref, ($val1 << 16) | $val2, $val3;
    $total_words += 3;

    if ( ($total_words % (64*1024)) <4) {
      $| = 1;
      print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\r";
      $| = 0;
    }
  }
  print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\n";
  close INPUT;
}
 
sub load_hostbuf
{
  my ($dataref, $fname) = @_;
  my ($val1, $val2, $val3, $val4);
  my ($total_words, $bychan_lines, $bytime_lines, $wordctr, $firstline) = (0, 0, 0, 0, 1);
  my ($lastseqn, $expectedseqn);

  open INPUT, $fname or die "Can't open $fname\n";
  binmode INPUT;

  while(!(eof INPUT)) {
    $val1 = ((ord getc INPUT) << 8) | (ord getc INPUT);
    $val2 = ((ord getc INPUT) << 8) | (ord getc INPUT);
    $val3 = ((ord getc INPUT) << 8) | (ord getc INPUT);
    $wordctr += 3;
    $total_words += 3;

    if ($wordctr == 3) {
      $val4 = ((ord getc INPUT) << 8) | (ord getc INPUT);
      $wordctr ++;
      $total_words++;
    }

    if ($firstline) {
      $firstline = 0;
      $lastseqn = $val1 - 1;
      $startts = $clock = 0;
    }

    if ($wordctr == 4) {
      $expectedseqn = ($lastseqn + 1 ) & 0xffff;
      if ( $expectedseqn != $val1) {
        print "At word $total_words, expected seqn $expectedseqn, got seqn $val1, lost ",
              ($val1 - $lastseqn - 1), " messages\n";
      }
      $lastseqn = $val1;
      if ($#$dataref > 4) {
        my($prevTs);
        $prevTs = $$dataref[$#$dataref - 1];
        # Spoof a push/pop to encapsulate the profile send message overhead
        # Start overhead at last trace in previous message ($prevTs)
        push @$dataref, $prevTs, ($profSendMsgTask << 10) | ($PUSH << 8);
        # End overhead with timestamp in header of new message
        push @$dataref, ($val3 << 16) | $val4, ($profSendMsgTask << 10) | ($POP << 8);
      }

    } else {
      push @$dataref, ($val1<<16) | $val2, $val3;
    }
    $wordctr = 0 if ($wordctr+3 > 128);
    if ( ($total_words % (64*1024)) <4) {
      $| = 1;
      print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\r";
      $| = 0;
    }
  }
  print "Read ",$total_words * 2, " bytes; ", ($#data + 1) / 2, " records\n";
}

sub listenport
{
  my ($dataref, $port) = @_;
  my ($hostname, $iaddr, $proto, $paddr, $ipaddr, $proto, $rempaddr);
  my ($remport, $remiaddr, $remipaddr);
  my ($rin, $rout, $data, $i);

  $hostname = hostname();
  $iaddr = gethostbyname($hostname);
  $ipaddr = inet_ntoa($iaddr);
  $paddr = sockaddr_in ($port, $iaddr);
  $proto = getprotobyname('udp');
  socket(SOCKET, PF_INET, SOCK_DGRAM, $proto)   || die "socket: $!";
  bind(SOCKET, $paddr)                          || die "bind: $!"; 
  print "Listening on $ipaddr:$port\n";
  $rin = '';
  vec($rin, fileno(SOCKET), 1) = 1;
  @$dataref = ();
  while (select($rout = $rin, undef, undef, undef)) {
     ($rempaddr = recv(SOCKET, $data, 2000, 0)) || die "recv: $!";
     ($remport, $remiaddr) = sockaddr_in($rempaddr);
     $remipaddr = inet_ntoa($remiaddr);
     for($i=0;$i<length($data);$i++) {
       print sprintf("%02x ", ord substr($data, $i, 1));
     }
     print "Got packet from $remipaddr:$remport length ", length($data), "\n";;
  }
  close(SOCKET);
}
