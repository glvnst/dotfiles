#!/bin/sh

chop() {
    # this is a shell function instead of an alias so that $COLUMNS is
    # evaluated at runtime, so a changing window width is supported
    expand | cut -c "1-${COLUMNS}"
}
