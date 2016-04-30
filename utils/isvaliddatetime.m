function rv = isvaliddatetime(s)
   try
      datetime(s);
      rv = true;
   catch
      rv = false;
   end
end