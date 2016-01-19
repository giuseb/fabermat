function rv = uisnapslider(slider)
%UISNAPSLIDER(SLIDER)
%   Snaps the SLIDER to the closest integer value and returns that value.
%   Useful in the context of a slider callback
v = round(slider.Value');
slider.Value = v;
rv = v;
