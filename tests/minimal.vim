set rtp+=.
if $PLENARY != "" && isdirectory($PLENARY)
  set rtp+=$PLENARY
else
  set rtp+=../plenary.nvim
endif
runtime! plugin/plenary.vim
