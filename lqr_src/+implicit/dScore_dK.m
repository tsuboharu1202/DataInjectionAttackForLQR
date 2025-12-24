function dScore_dK = dScore_dK(sd,K_temp,P)
% 確認済み

A = sd.A;
B = sd.B;
Q = sd.Q;
R = sd.R;
KP = K_temp*P;
n = size(A,1);
m = size(B,2);

dP_dK = implicit.dP_dK_score(sd,K_temp,P);

dKPKT_dK = kron(KP,speye(m)) + kron(speye(m),KP)*implicit.commutation(m,n) + kron(K_temp,K_temp)*dP_dK;
dScore_dK = (Q(:))'*dP_dK + (R(:))'*dKPKT_dK;
end