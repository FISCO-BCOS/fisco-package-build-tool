BEGIN { 
    transaction_count=0;
    blk_count=0;
    # Add to do
} 

{
   if( $0 ~ /\[NETWORK\]/ ) {
        err[0]++ ;
    }
    else if( $0 ~ /getLeader/ ) {
		err[1]++ ;
		match($0,/<([0-9]+),([0-9]+)>/,node);
		get_leader_err[node[2]]++
    }
    else if( $0 ~ /ChangeViewWarning/ ) {
        err[2]++ ;
    }
    else if( $0 ~ /WARNING.*Closing/ ) {
        err[3]++ ;
    }
    else if ( $0 ~ /Generating seal/ ) {
        # 
        match($0,/([0-9]+)tx/,blk);
        split( $0, t , "|");
        pbft_pre[blk[1]]=t[2];
    }
    else if( $0 ~ /tq.num/ ) {
        # tq.num too much log
        match($0,/tq.num=([0-9]+)/,tqc);
        if ( tqc[1] > 512 ) {
            err[4]++ ;
        }
    }
    else if( $0 ~ /Block::exec txExec/ ) {
        # block exec too slowly log
        err[5]++ ;
    }
    else if( $0 ~ /state commit timecost/ ) {
        # commit too slowly log
        err[6]++ ;
    }
    else if ( $0 ~ /Report.*idx/ ) {
        match($0,/idx=([0-9]+)/,idx);
        report[idx[1]]++;

        match($0,/blk=([0-9]+)/,blk);
        split( $0, t , "|")
        pbft_write[blk[1]]=t[2]
    }
    else if ( $0 ~ /Imported and best/ ) {
        # transaction count , blk count
        match($0,/size=([0-9]+)/,size);
        transaction_count+=size[1];
        blk_count+=1;
    }
    else if ( $0 ~ /Reach enough sign/ ) {
        # pbft second phase
        match($0,/block=([0-9]+)/,blk);
        split( $0, t , "|")
        pbft_sign[blk[1]]=t[2]
    }
    else if ( $0 ~ /Reach enough commit/ ) {
        # pbft third phase
        match($0,/block=([0-9]+)/,blk);
        split( $0, t , "|")
        pbft_commit[blk[1]]=t[2]
    }
    else if ( $0 ~ /handleViewChangeMsg.*success/ ) {
        # view message handle 
        match($0,/idx=([0-9]+)/,idx);
        match($0,/from=([0-9]+)/,from);
        view_total[idx[1]]++
        # view_d : direct send message  view_f : view message forward
        if ( idx[1] == from[1] ) {
            view_d[idx[1]]++
        } else {
            view_f[idx[1]]++
        }
    }
    else if ( $0 ~ /handleSignMsg.*success/ ) {
        # 
        match($0,/idx=([0-9]+)/,idx);
        match($0,/from=([0-9]+)/,from);
        sign_total[idx[1]]++
        if ( idx[1] == from[1] ) {
            sign_d[idx[1]]++
        } else {
            sign_f[idx[1]]++
        }
    }
    else if ( $0 ~ /handlePrepareMsg.*success/ ) {
        # pbft first phase
        match($0,/idx=([0-9]+)/,idx);
        match($0,/from=([0-9]+)/,from);
        match($0,/blk=([0-9]+)/,blk);
        pre_total[idx[1]]++
        if ( idx[1] == from[1] ) {
            pre_d[idx[1]]++
        } else {
            pre_f[idx[1]]++
        }

        # INFO|2018-12-12 14:20:21:974|handlePrepareMsg: idx=1,view=14377,blk=85,hash=3fbf7bc0…,from=1,real_block_hash=d736dbd7… success
        split( $0, t , "|")
        pbft_pre[blk[1]]=t[2]
    }
    else if ( $0 ~ /handleCommitMsg.*success/ ) {
        match($0,/idx=([0-9]+)/,idx);
        match($0,/from=([0-9]+)/,from);
        commit_total[idx[1]]++
        if ( idx[1] == from[1] ) {
            commit_d[idx[1]]++
        } else {
            commit_f[idx[1]]++
        }
    }
} 

END {
    # transaction+=size
    # blk_count+=size
    print "transaction_count="transaction_count
    print "blk_count="blk_count

    # err message result
    for (k in err) {
        print "err["k"]="err[k]
    }
	
    # getLeader error
    for (k in get_leader_err) {
        print "get_leader_err["k"]="get_leader_err[k]
    }

    # report blk result
    for (k in report) {
        print "report["k"]="report[k]
    }

    # view message
    for (k in view_total) {
        print "view_total["k"]="view_total[k]
    }

    # direct view message
    for (k in view_d) {
        print "view_d["k"]="view_d[k]
    }

    # forward view message
    for (k in view_f) {
        print "view_f["k"]="view_f[k]
    }

    # pre
    for (k in pre_total) {
        print "pre_total["k"]="pre_total[k]
    }

    # direct pre message
    for (k in pre_d) {
        print "pre_d["k"]="pre_d[k]
    }

    # forward view message
    for (k in pre_f) {
        print "pre_f["k"]="pre_f[k]
    }

    # sign
    for (k in sign_total) {
        print "sign_total["k"]="sign_total[k]
    }

    # direct sign message
    for (k in sign_d) {
        print "sign_d["k"]="sign_d[k]
    }

    # forward view message
    for (k in sign_f) {
        print "sign_f["k"]="sign_f[k]
    }

    # commit
    for (k in commit_total) {
        print "commit_total["k"]="commit_total[k]
    }

    # direct commit message
    for (k in commit_d) {
        print "commit_d["k"]="commit_d[k]
    }

    # forward commit message
    for (k in commit_f) {
        print "commit_f["k"]="commit_f[k]
    }

    # pbft first phase
    for (k in pbft_pre) {
        print "pbft_pre["k"]=\""pbft_pre[k]"\""
    }

    # pbft second phase
    for (k in pbft_sign) {
        print "pbft_sign["k"]=\""pbft_sign[k]"\""
    }

    # pbft commit phase
    for (k in pbft_commit) {
        print "pbft_commit["k"]=\""pbft_commit[k]"\""
    }

    # pbft end with write block
    for (k in pbft_write) {
        print "pbft_write["k"]=\""pbft_write[k]"\""
    }
}