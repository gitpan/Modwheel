#wc -l * config/* lib/* lib/*/* lib/*/*/* lib/*/*/*/* t/* t/*/* doc/* Templates/Simple/*/* Templates/Simple/* Templates/SimpleAdmin/* Templates/SimplateAdmin/*/* sql/* utils/*
DIRS=". /opt/modwheel/Templates"
a=0;
for dir in "$DIRS";
do
    for f in $(find $dir -type f | grep -v CVS | grep -v Scriptaculous | grep -v testfilenames | grep -v javascript | grep -v .gz);
    do
        c=$(wc -l "$f" | awk '{print $1}');
        a=$(expr $a + $c);
    done
done
echo $a

exit

for dir in "$DIRS"
do
    for f in $(find $dir -type f | grep -v CVS | grep -v Scriptaculous | grep -v testfilenames | grep -v javascript | grep -v .gz);
    do
        wc -l "$f";
    done
done
