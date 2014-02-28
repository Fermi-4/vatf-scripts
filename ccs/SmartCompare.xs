/*
 *  Copyright 2013 by Texas Instruments Incorporated.
 *
 */

/*
 *  ======== smartCompare.xs ========
 *
 */

/*
 *  ======== smartComp ========
 *  This function supports an intelligent output comparison by allowing the
 *  golden output file to specify tokens in the output to ignore using printf-
 *  style formatting. For example, the golden output file may include a line
 *  Loop count = %d
 *  and the comparison function will ignore any number in place of the %d.
 *  Currently supported are %d for digits and %x for hexadecimal. %x will match
 *  lower or uppercase hex digits, but does not look for '0x'. If the test
 *  outputs something like 0x1B53, then the k file should be 0x%x to ignore
 *  that value.
 *  Also, lines of output can be skipped entirely by starting the line with #.
 */
function smartComp(output, golden)
{
    var lineNum = 0;
    while (((outLine = output.readLine()) != null) &&
           ((goldLine = golden.readLine()) != null)) {
        lineNum++;
        /* Just compare the whole lines first (vast majority will match) */
        if (!outLine.equals(goldLine)) {
            /*
             * Ignore the line if the golden file line begins with IGNORE_LINE.
             */
            if (goldLine.substr(0, String("IGNORE_LINE").length) ==
                "IGNORE_LINE") {
                continue;
            }
            if (goldLine.length()==0 || outLine.length()==0) {
                return("Length mismatch on line " + lineNum);
            }

            /*
             *  Log lines begin with a '#'. The sequence number and message
             *  must match exactly, the rest of the line is ignored.
             *  #0000000001 [t=0x00020f04] {module#768}: LM_EVENT: user event
             */
            if ((goldLine.substring(0,1) == '#') || (goldLine.substring(0,1) == '[')) {
                if (goldLine.substring(0,1) == '#') {
                    /* The sequence numbers should match exactly */
                    var goldSeq = goldLine.substr(0, String("#0000000000").length);
                    var outSeq = outLine.substr(0, String("#0000000000").length);

                    if (!goldSeq.equals(outSeq)) {
                        return("Log sequence # mismatch on line " + lineNum);
                    }
                }

                /*
                 * The timestamp may contain a ':' to indicate a range of
                 * times, so it's not sufficient to simply find the first
                 * instance of ':' as the start of the message. Also, the
                 * timestamp is optional.
                 */
                var timestamp = /\[t\=0x[a-zA-Z0-9\:\%]+\]/g;

                /*
                 * These two vars hold the index to start searching for
                 * the ':' for the message.
                 */
                var goldStart = 0;
                var outStart = 0;

                if (timestamp.exec(goldLine) != null) {
                    goldStart = timestamp.lastIndex;
                }

                /* Reset lastIndex before using the RegExp on a new string */
                timestamp.lastIndex = 0;

                if (timestamp.exec(outLine) != null) {
                    outStart = timestamp.lastIndex;
                }

                /*
                 * The messages may contain formatters. If the messages match,
                 * continue to the next line of output, otherwise fall through
                 * to the formatter check.
                 */
                goldLine = goldLine.substring(goldLine.indexOf(':', goldStart),
                                              goldLine.length());
                outLine = outLine.substring(outLine.indexOf(':', outStart),
                                            outLine.length());
                if (goldLine.equals(outLine)) {
                    continue;
                }
            }

            /*
             * If the lines don't match and there's no % token in the golden
             * output, then the test failed.
             */
            if (goldLine.indexOf('%') == -1) {
                return("Mismatch on line " + lineNum);
            }
            /*
             * Compare the two character by character, checking for '%'.
             * i is the index in goldLine, j is the index in outLine.
             */
            var j = 0;
            for (var i = 0; i < goldLine.length(); i++) {
                if (j >= outLine.length()) {
                    return("Mismatch on line " + lineNum + " char " + i);
                }
                /* Compare token */
                if ((String.fromCharCode(goldLine.charAt(i)) == "%") && (i != goldLine.length()-1)) {
                    switch(String.fromCharCode(goldLine.charAt(i+1))) {
                        case 'd':
                            /* Move i past the %d */
                            i += 2;

                            /* The first character may be a '-' */
                            if (String.fromCharCode(outLine.charAt(j)) == '-') {
                                j++;
                            }

                            /* Check for digits until a separator is found. */
                            for (; j < outLine.length(); j++) {
                                var ch = String.fromCharCode(outLine.charAt(j));
                                /*
                                 * If it's a space, continue, next time around
                                 * will check to make sure spaces match.
                                 */
                                if (isSeparator(ch)) {
                                    break;
                                }
                                if (!isDigit(ch)) {
                                    return("Number formatting syntax error on line " + lineNum);
                                }
                            }
                            break;
                        case 'x':
                            /* Move i past the %x */
                            i += 2;

                            for (; j < outLine.length(); j++) {
                                var ch = String.fromCharCode(outLine.charAt(j));
                                /*
                                 * If it's a space, continue, next time around
                                 * will check to make sure spaces match.
                                 */
                                if (isSeparator(ch)) {
                                    break;
                                }
                                if (!isHex(ch)) {
                                    return("Number formatting syntax error on line " + lineNum);
                                }
                            }
                            break;
                        default:
                        /* Just treat it as a character. */
                    }
                }

                /* if at both end of lines, bail here */
                if ((i >= goldLine.length()) && (j >= outLine.length())) {
                    return(null);
                }

                /* if either at end of line, Mismatch */
                if ((i >= goldLine.length()) || (j >= outLine.length())) {
                    return("Mismatch on line " + lineNum + " char " + i);
                }

                /*
                 * This check compares normal characters in the output as well
                 * as the 'space' character which terminated a token. That's
                 * why it runs each time and isn't an 'else if'.
                 */
                if (String.fromCharCode(goldLine.charAt(i)) != String.fromCharCode(outLine.charAt(j))) {
                    return("Mismatch on line " + lineNum + " char " + i);
                }
                j++;
            }
        }
    }

    /* Make sure the files are the same length (both should be at end) */
    if (((outLine = output.readLine()) != null) || ((goldLine = golden.readLine()) != null)) {
        return("Differing line count");
    }
    /* Success */
    return(null);
}

/*
 *  ======== isSeparator ========
 */
function isSeparator(ch)
{
    var separators = " ():,.;'\"|/\\`{}[]%";

    if (separators.indexOf(ch) != -1) {
        return (true);
    }

    return (false);
}

/*
 *  ======== isDigit ========
 */
function isDigit(num)
{
    if (num.length > 1) {
        return (false);
    }

    var digits = "1234567890";
    if (digits.indexOf(num) != -1) {
        return (true);
    }

    return (false);
}


/*
 *  ======== isHex ========
 */
function isHex(num)
{
    if (num.length > 1) {
        return (false);
    }

    var hex = "1234567890abcdefABCDEF";
    if (hex.indexOf(num) != -1) {
        return (true);
    }

    return (false);
}

/*
 *  ======== getFile ========
 *  java.io.File interperets the backslashes in paths as escape chars.
 *  This helper function fixes that.
 */
function getFile(filename)
{
    return(java.io.File(java.io.File(filename).getCanonicalPath()));
}
