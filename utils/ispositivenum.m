function rv = ispositivenum(number)
rv = and(isnumeric(number), number > 0);