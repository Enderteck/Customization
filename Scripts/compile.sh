#!/bin/bash
cc "$@" -Wall -Werror -Wextra -pedantic -std=gnu89 -Wno-long-long -O0 -ggdb -fno-omit-frame-pointer -o test