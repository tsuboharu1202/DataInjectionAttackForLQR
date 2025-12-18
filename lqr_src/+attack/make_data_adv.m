function [X_adv, Z_adv, U_adv] = make_data_adv(sd, X_grad,Z_grad, U_grad, eps_att)
% make_data_adv: 勾配から攻撃データを生成
%   eps_att: 攻撃制約（オプション、指定しない場合はcfg.Const.ATTACKER_UPPERLIMITを使用）

if nargin < 5 || isempty(eps_att)
    eps_att = cfg.Const.ATTACKER_UPPERLIMIT;
end

X_adv = d_adv_add(sd.X, X_grad, eps_att);
Z_adv = d_adv_add(sd.Z, Z_grad, eps_att);
U_adv = d_adv_add(sd.U, U_grad, eps_att);

    function d_adv = d_adv_add(d_ori, d_grad, eps)
        d_adv = d_ori + eps .* sign(d_grad);
    end
end