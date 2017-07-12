function reduction_dir

   ;; Find the reduction directory from the miv_help procedure
mivhproname = clobber_dir(file_which('miv_help.pro'),dir=reddir)

return,reddir
end
