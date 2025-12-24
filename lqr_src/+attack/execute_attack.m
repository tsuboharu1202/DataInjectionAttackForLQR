function [X_adv, Z_adv, U_adv, history] = execute_attack(system_data, method, eps_att, save_history)
% execute_attack: Execute attack method on system data
%
% Inputs:
%   system_data: System data to attack
%   method: Attack method (cfg.AttackType)
%   eps_att: (optional) Attack parameter (for DGSM methods)
%   save_history: (optional) If true, save attack history (only for IDGSM methods)
%
% Outputs:
%   X_adv, Z_adv, U_adv: Adversarial data
%   history: (optional) Attack history (only for IDGSM methods if save_history=true)

if nargin < 3
    eps_att = [];
end
if nargin < 4
    save_history = false;
end

history = [];

switch method
    case cfg.AttackType.DIRECT_DGSM_EV
        [X_adv, Z_adv, U_adv] = attack.dgsm_ev(system_data, true, eps_att);
        
    case cfg.AttackType.DIRECT_IDGSM_EV
        if save_history
            [X_adv, Z_adv, U_adv, history] = attack.idgsm_ev(system_data, true, save_history);
        else
            [X_adv, Z_adv, U_adv] = attack.idgsm_ev(system_data, true);
        end
        
    case cfg.AttackType.DIRECT_DGSM_SCORE
        [X_adv, Z_adv, U_adv] = attack.dgsm_score(system_data, true, eps_att);
        
    case cfg.AttackType.DIRECT_IDGSM_SCORE
        [X_adv, Z_adv, U_adv] = attack.idgsm_score(system_data, true);
        
    case cfg.AttackType.IMPLICIT_DGSM_EV
        [X_adv, Z_adv, U_adv] = attack.dgsm_ev(system_data, false, eps_att);
        
    case cfg.AttackType.IMPLICIT_IDGSM_EV
        if save_history
            [X_adv, Z_adv, U_adv, history] = attack.idgsm_ev(system_data, false, save_history);
        else
            [X_adv, Z_adv, U_adv] = attack.idgsm_ev(system_data, false);
        end
    case cfg.AttackType.IMPLICIT_DGSM_SCORE
        [X_adv, Z_adv, U_adv] = attack.dgsm_score(system_data, false, eps_att);
        
    case cfg.AttackType.IMPLICIT_IDGSM_SCORE
        if save_history
            [X_adv, Z_adv, U_adv, history] = attack.idgsm_score(system_data, false, save_history);
        else
            [X_adv, Z_adv, U_adv] = attack.idgsm_score(system_data, false);
        end
        
    otherwise
        error('attack:unknownMethod','Unknown attack method: %s', string(method));
end
end