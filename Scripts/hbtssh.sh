#!/bin/bash
infocmp -x xterm-ghostty | ssh $2 -- tic -x -

ssh -p $1 $2
