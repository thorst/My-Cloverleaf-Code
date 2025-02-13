if 0 {
    _filter collection ?-s? iteratee/list|shorthand/dict|shorthand
    collection is the list or list of dicts
    -s optioanlly say you are using the shorthand syntax
    iteratee item ?index? ?collection?
    item - current item of collection, typically abbriviated "o"
    index - index of current item in collection, typically abbriviated "i"
    collection - the entire collection, typically abbriviated "c"
    Alternatively the iteratee can be a list or dictionary,
    see examples

    About:
    Goal is to mimic the filter function from lodash
    Allows user to filter a list or list of dicionaries
    based on dynamic criteria. When criteria returns
    truthy item is included in collection to return

    Tests/Examples:


    Change Log:
    10-17-2017 - TMH
    -Initial version
}
if 0 {

    ###############################################################
    # Lodash
    ###############################################################

    Lodash Javascript Examples Below
    Documentation: https://lodash.com/docs/4.17.4#filter

    var users = [
    { 'user': 'barney', 'age': 36, 'active': true },
    { 'user': 'fred',   'age': 40, 'active': false }
    ];

    ======== EXAMPLE 1==========
    _.filter(users, function(o) { return !o.active; });
    // => objects for ['fred']

    ======== EXAMPLE 2==========
    // The `_.matches` iteratee shorthand.
    _.filter(users, { 'age': 36, 'active': true });
    // => objects for ['barney']

    ======== EXAMPLE 3==========
    // The `_.matchesProperty` iteratee shorthand.
    _.filter(users, ['active', false]);
    // => objects for ['fred']

    ======== EXAMPLE 4==========
    // The `_.property` iteratee shorthand.
    _.filter(users, 'active');
    // => objects for ['barney']
}
if 0 {

    ###############################################################
    # lsearch
    ###############################################################
    lsearch has index which is nice but it requires that you
    order is consistent and never changing. Since this is
    less of a reality and the syntax is a little verbose I saw
    value to create an _filter

    # Here are some examples of lsearch index
    set somelist {{aaa 1} {bbb 2} {ccc 1} {ddd 2}}
    echo [lsearch -index 0 -all -inline $somelist bbb]  ;# >> {bbb 2}
    echo [lsearch -index 0 -all $somelist "bbb"]        ;# >> 1
    echo [lsearch -index 0 -all $somelist "ccc"]        ;# >> 2
    echo [lsearch -index 1 -all -inline $somelist "2"]  ;# >> 2

    # Using these samples we can make due with lsearch to complete
    # Lodashs first and fourth example. However the second and third
    # cant be mimiced because they are acting upon multiple keys
    # These we can do because its just a boolean, or a static value
    set users [list \
        [dict create user barney age 36 active true] \
        [dict create user fred age 40 active false] \
    ]
echo -[lsearch -index 5 -all -inline $users false]-
echo -[lsearch -index 1 -all -inline $users "barney"]-

}
proc _filter {collection predicate args} {

    # They want to use shorthand syntax
    if {$predicate=="-s"} {

        # They passed a list/dict
        if {[_dictIs {*}$args]} {
            set predicate {x {
                upvar args args
                set truthy 1
                dict for {k v} {*}$args {
                    if {[dict get $x $k]!=$v} {
                        set truthy false
                        break
                    }
                }
                return $truthy
                }}

                # They passed just an individual string
            } else {
                set predicate {x {
                    upvar args args;
                    if {[dict get $x $args]} {
                        return true;
                    }
                    return false;
                    }}
                }
            }

            # Start the result list and the index (which may not be used)
            set result {}
            set i -1

            # For each item in collection apply the iteratee.
            # Dynamically pass the correct parameters.
            set paramLen [llength [lindex $predicate 0]]
            foreach item $collection {
                set param [list $item]
                if {$paramLen>=2} {lappend param [incr i];}
                if {$paramLen>=3} {lappend param $collection;}
                if {[apply $predicate {*}$param]} {
                    lappend result $item
                }
            }
            return $result
        }