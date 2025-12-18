function score = real_score(sd, K)
% 離散時間用: Acl が安定(ρ<1)なら J(K)=tr(QP)+tr(K' R K P) を返す
% 安定でなければ score = Inf
    Acl = sd.A + sd.B*K;
    rho = max(abs(eig(Acl)));
    isStable = (rho < 1 - 1e-10);   % 少しだけ余裕

    if ~isStable
        score = Inf;
        return
    end
    n = size(sd.A,1);
    P = dlyap(Acl, eye(n));
    score = trace(sd.Q * P) + trace((K.' * sd.R * K) * P);
end
