function rv = isvalidfilename(fn)
   if ishstring(fn) && ~isempty(regexp(fn, '^[\w/.-]+$', 'ONCE'))
      rv = true;
   else
      rv = false;
   end
end