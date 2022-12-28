# awk script for converting man2html openvpn output
#
# taken from https://gist.github.com/QueuingKoala/5985986

{
        # Matching lines means we skip this many
        if ( match($0, "^Content-type: ") ) skip=2
	if ( match($0, "Return to Main Contents") ) skip=1
	# Rip out the "Updated" date as it's wrong:
        if ( match($0, "^Section: ") ) 
		sub("Updated: .*<BR>", "")

        # replace localhost HREF <A> tags and their closing pair
        if ( match($0, "<A HREF=\"http://localhost/.*\">") )
        {
                sub("<A HREF=\"http://localhost/.*\">", "")
                sub("</A>", "")
        }

        # see if we need to skip lines. If not, print the buffer
        if ( skip == 0 ) { print }
        else { skip-- }
}
