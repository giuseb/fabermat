function vs = validatewindow(type)
   validwins = {
      'hann'
      'hamming'
      'blackman'
      'blackmanharris'
      'kaiser'
      };
   vs = validatestring(type, validwins);
end