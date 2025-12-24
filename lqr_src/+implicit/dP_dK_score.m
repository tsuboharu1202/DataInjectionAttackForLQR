function dP_dK = dP_dK_score(sd,K_temp,P)
% 確認済み

A = sd.A;
B = sd.B;
Q = sd.Q;
R = sd.R;
Ac = A+B*K_temp;
n = size(A,1);
m = size(B,2);

dF_dP = speye(n^2) - kron(Ac,Ac);
dF_dK = kron(Ac*P,B) + kron(B,Ac*P)*implicit.commutation(m,n);

dP_dK = dF_dP \ (-dF_dK);

end





