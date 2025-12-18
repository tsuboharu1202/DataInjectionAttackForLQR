function [X_adv, Z_adv, U_adv] = execute_attack(system_data, method, eps_att)
if nargin < 3
    eps_att = [];
end
switch method
    case cfg.AttackType.DIRECT_DGSM_EV
        [X_adv, Z_adv, U_adv] = attack.dgsm_ev(system_data, true, eps_att);
        
    case cfg.AttackType.DIRECT_IDGSM_EV
        [X_adv, Z_adv, U_adv] = attack.idgsm_ev(system_data,true);
        
    case cfg.AttackType.DIRECT_DGSM_SCORE
        [X_adv, Z_adv, U_adv] = attack.dgsm_score(system_data, true, eps_att);
        
    case cfg.AttackType.DIRECT_IDGSM_SCORE
        [X_adv, Z_adv, U_adv] = attack.idgsm_score(system_data,true);
        
    case cfg.AttackType.IMPLICIT_DGSM_EV
        [X_adv, Z_adv, U_adv] = attack.dgsm_ev(system_data, false, eps_att);
        
    case cfg.AttackType.IMPLICIT_IDGSM_EV
        [X_adv, Z_adv, U_adv] = attack.idgsm_ev(system_data, false);
        
    otherwise
        error('attack:unknownMethod','Unknown attack method: %s', string(method));
end
end