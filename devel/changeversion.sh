#!/bin/bash
find . -type f \( ! -name 'Changes' \) -exec perl -pi -e's/0\.2\.1/0.2.2/g' {}
\;
