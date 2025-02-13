proc _pidKill {pid} {
    exec ksh -c "kill -9 $pid"
}