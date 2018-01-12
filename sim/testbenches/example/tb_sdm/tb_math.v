
function real abs(input real x);
  begin
    if(x < 0.0)
      abs = -1.0 * x;
    else
      abs = x;
  end
endfunction

function real exp(input real x);
  real x2, x3, x4, x5;
  begin
    x2 = x * x;
    x3 = x * x2;
    x4 = x * x3;
    x5 = x * x4;
    exp = 1.0 + x + 0.5 * x2 + 0.16666667 * x3 + 0.04166667 * x4 + 8.33333333e-3 * x5;
  end
endfunction

function real sin(input real x);
  real sign, sum;
  real s1, s3, s5;
  begin
    sign = 1.0;
    s1 = x;
    if(s1 < 0.0)
      begin
        s1 = -s1;
        sign = -1.0;
      end
    while(s1 > `PI / 2.0)
      begin
        s1 = s1 - `PI;
        sign = -1.0 * sign;
      end
    s3 = s1 * s1 * s1;
    s5 = s3 * s1 * s1;
    sum = s1 - 0.16666667 * s3 + 8.33333333e-3 * s5;
    sin = sum * sign;
  end
endfunction

