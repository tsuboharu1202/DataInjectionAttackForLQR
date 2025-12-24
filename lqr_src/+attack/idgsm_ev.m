function [X_adv, Z_adv, U_adv, history] = idgsm_ev(ori_sd,direct_flag,save_history)
% idgsm_ev: Implicit Direct Gradient-based Score Method for eigenvalue attack
%
% Inputs:
%   ori_sd: Original system data
%   direct_flag: true for direct gradient, false for implicit gradient
%   save_history: (optional) if true, save noise history at each step
%
% Outputs:
%   X_adv, Z_adv, U_adv: Adversarial data
%   history: (optional) struct with fields:
%       - dX_history: cell array of dX at each step
%       - dZ_history: cell array of dZ at each step
%       - dU_history: cell array of dU at each step
%       - spectral_radius_history: array of spectral radius at each step
%       - iter_count: number of iterations

if nargin < 3
    save_history = false;
end

iter = 0;

checkX = false(size(ori_sd.X));   % dX と同じ大きさの logical false
checkZ = false(size(ori_sd.Z));
checkU = false(size(ori_sd.U));

is_continue = true;

dX = zeros(size(ori_sd.X));
dZ = zeros(size(ori_sd.Z));
dU = zeros(size(ori_sd.U));
current_sd = ori_sd;

% Initialize history if requested
if save_history
    history = struct();
    history.dX_history = {};
    history.dZ_history = {};
    history.dU_history = {};
    history.spectral_radius_history = [];
    history.iter_count = 0;
else
    history = [];
end

% 局所最適解回避用の変数
spectral_radius_history = [];  % スペクトル半径の履歴を保持

while is_continue
    disp("iter");disp(iter);
    [X_grad, Z_grad, U_grad] = calc_grad(current_sd);
    dX = dX + cfg.Const.IDGSM_ALPHA*X_grad;
    dZ = dZ + cfg.Const.IDGSM_ALPHA*Z_grad;
    dU = dU + cfg.Const.IDGSM_ALPHA*U_grad;
    
    [dX,dZ,dU,checkX,checkZ,checkU] = attack.projector(dX,dZ,dU,checkX,checkZ,checkU);
    
    okX = all(checkX(:));   % R2018b+ なら all(checkX,"all") でもOK
    okZ = all(checkZ(:));
    okU = all(checkU(:));
    
    X_adv = ori_sd.X + dX;
    Z_adv = ori_sd.Z + dZ;
    U_adv = ori_sd.U + dU;
    
    allDone = okX && okZ && okU;
    current_sd = datasim.SystemData(ori_sd.A,ori_sd.B,ori_sd.Q,ori_sd.R,X_adv,Z_adv,U_adv);
    K_temp = current_sd.opt_K();
    spectral_radius_temp = max(abs(eig(ori_sd.A+ori_sd.B*K_temp)));
    disp("spectral_radius_temp");disp(spectral_radius_temp);
    
    % 局所最適解回避: i回目とi+IDGSM_STAGNATION_STEPS回目を比較
    if cfg.Const.IDGSM_ESCAPE_LOCAL_MIN && iter >= cfg.Const.IDGSM_STAGNATION_STEPS
        % IDGSM_STAGNATION_STEPSステップ前のスペクトル半径と比較
        prev_rho_idx = iter - cfg.Const.IDGSM_STAGNATION_STEPS + 1;  % +1は0-indexedから1-indexedへの変換
        if prev_rho_idx > 0 && prev_rho_idx <= length(spectral_radius_history)
            prev_spectral_radius = spectral_radius_history(prev_rho_idx);
            rho_change = abs(spectral_radius_temp - prev_spectral_radius);
            if rho_change <= cfg.Const.IDGSM_RHO_CHANGE_THRESHOLD
                % ランダムノイズを加える
                noise_scale = cfg.Const.IDGSM_RANDOM_NOISE_SCALE * cfg.Const.ATTACKER_UPPERLIMIT;
                dX = dX + noise_scale * randn(size(dX));
                dZ = dZ + noise_scale * randn(size(dZ));
                dU = dU + noise_scale * randn(size(dU));
                fprintf('局所最適解回避: ランダムノイズを追加 (iter=%d, prev_iter=%d, rho_change=%.2e)\n', iter, prev_rho_idx-1, rho_change);
                % ノイズを加えたので、再度projectorを通す
                [dX,dZ,dU,checkX,checkZ,checkU] = attack.projector(dX,dZ,dU,checkX,checkZ,checkU);
                % 更新されたノイズで再度スペクトル半径を計算
                X_adv = ori_sd.X + dX;
                Z_adv = ori_sd.Z + dZ;
                U_adv = ori_sd.U + dU;
                current_sd = datasim.SystemData(ori_sd.A,ori_sd.B,ori_sd.Q,ori_sd.R,X_adv,Z_adv,U_adv);
                K_temp = current_sd.opt_K();
                spectral_radius_temp = max(abs(eig(ori_sd.A+ori_sd.B*K_temp)));
            end
        end
    end
    
    % Save history if requested
    if save_history
        history.dX_history{end+1} = dX;
        history.dZ_history{end+1} = dZ;
        history.dU_history{end+1} = dU;
        history.spectral_radius_history(end+1) = spectral_radius_temp;
    end
    
    % スペクトル半径の履歴を記録（局所最適解回避用）
    spectral_radius_history(end+1) = spectral_radius_temp;
    
    is_continue = ~allDone && (iter < cfg.Const.MAX_ITERATION) && (spectral_radius_temp < 1.0);
    
    iter = iter + 1;  % Increment the iteration counter
end

if save_history
    history.iter_count = iter;
end


    function [X_grad, Z_grad, U_grad] = calc_grad(sd)
        if(direct_flag)
            [X_grad, Z_grad, U_grad] = grad.direct_ev(sd);
        else
            [X_grad, Z_grad, U_grad] = grad.implicit_ev(sd);
        end
    end
end
