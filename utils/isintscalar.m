function rv = isintscalar(number)
rv = isnumscalar(number) && round(number)==number;