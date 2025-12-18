function E = E_select(p1, p2, which)
% E_select: selection matrix used in the paper to pick diagonal blocks.
% For F = diag(F1,F2) with sizes p1 and p2, define:
%   Ē1 = [ I_{p1}; 0_{p2,p1} ]   (size (p1+p2)×p1)
%   Ē2 = [ 0_{p1,p2}; I_{p2} ]   (size (p1+p2)×p2)
% This function returns Ē1 when which=1, Ē2 when which=2.

if which == 1
    E = [speye(p1); sparse(p2,p1)];
elseif which == 2
    E = [sparse(p1,p2); speye(p2)];
else
    error('implicit:badESelect','which must be 1 or 2');
end
end



