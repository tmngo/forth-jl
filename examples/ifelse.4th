: emitseven 115 emit 101 emit 118 emit 101 emit 110 emit ;
: emitnot 110 emit 111 emit 116 emit ;
: is7ornot 7 = if emitseven else emitnot emitseven then ;
6 dup cr . is7ornot
7 dup cr . is7ornot
8 dup cr . is7ornot